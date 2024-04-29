
# digital-edition-archive

## Installation instructions

### Version control
* deploy the generated project files to your own Git repository

### Build
* clone / checkout project from git repository
* run `mvn clean install`

### Create / find  the directory with the MyCoRe Commandline interface
* unpack `digital-edition-archive-cli/target/digital-edition-archive-cli.tar` into a user defined CLI directory and change into it
* OR: use the generated CLI directory in `digital-edition-archive/digital-edition-archive-cli/target/appassembler`
* remember that you can start the CLI with `bin\digital-edition-archive.bat` on Windows and `bin/digital-edition-archive.sh` on MAC/Linux
* remember that you can exit the CLI with the command `exit`


### Configure and run Solr server
* Change to `digital-edition-archive-webapp` directory
* Install and configure solr with the commands: 
  * `mvn solr-runner:copyHome`
  * `mvn solr-runner:installConfigSet@cs_main`
  * `mvn solr-runner:installConfigSet@cs_classification`

* Run solr with the command `mvn solr-runner:start` 
* (Solr is usually running at: http://localhost:8983/solr/#/)
* (To stop it return to this directory an run: `mvn solr-runner:stop`)

### Configure the application
* change into CLI directory and run:
  `bin/digital-edition-archive.sh create configuration directory`
  * The configuration directory is created in: `~/.mycore/digital-edition-archive`
  * (ignore the CLI output `jakarta.persistence.PersistenceException: No Persistence provider for EntityManager named MyCoRe`,
     because the database will be configured by the next steps)
* configure your database connection in `~/.mycore/digital-edition-archive/resources/META-INF/persistence.xml`
  * (for first steps you can use the preconfigured H2 database)
  * (if you leave the jdbc url unchanged, it will be updated by the next command, pointing to an H2 database file in your data directory)
  * perhaps you need to download a driver to `~/.mycore/digital-edition-archive/lib/`
* run cli command `bin/digital-edition-archive.sh reload mappings in jpa configuration file`
* configure Solr cores in `~/.mycore/digital-edition-archive/mycore.properties`

```
MCR.Solr.ServerURL=http://localhost:8983/
MCR.Solr.Core.main.Name=main
MCR.Solr.Core.main.ServerURL=%MCR.Solr.ServerURL%
MCR.Solr.Core.classification.Name=classifications
MCR.Solr.Core.classification.ServerURL=%MCR.Solr.ServerURL%
```

### Initialize the application
* change into CLI directory (see above)
* load default data by running: `bin/digital-edition-archive.sh process resource setup-commands.txt`

### Run web server
* Change to `digital-edition-archive-webapp` directory
* Run Jetty with the command: `mvn jetty:run` (end with `ctrl+c`)
* Open your browser with: http://localhost:8080/
* (Fast rebuild and Jetty restart `mvn clean install && cd digital-edition-archive-webapp && mvn jetty:run` (End with ctrl+c))
