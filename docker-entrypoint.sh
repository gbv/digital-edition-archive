#!/usr/bin/bash
set -e

MCR_SAVE_DIR="${MCR_CONFIG_DIR}save/"

MCR_CONFIG_DIR_ESCAPED=$(echo "$MCR_CONFIG_DIR" | sed 's/\//\\\//g')
MCR_DATA_DIR_ESCAPED=$(echo "$MCR_DATA_DIR" | sed 's/\//\\\//g')
MCR_SAVE_DIR_ESCAPED=$(echo "$MCR_SAVE_DIR" | sed 's/\//\\\//g')
MCR_LOG_DIR_ESCAPED=$(echo "$MCR_LOG_DIR" | sed 's/\//\\\//g')

SOLR_URL_ESCAPED=$(echo "$SOLR_URL" | sed 's/\//\\\//g')
SOLR_CORE_ESCAPED=$(echo "$SOLR_CORE" | sed 's/\//\\\//g')
SOLR_CLASSIFICATION_CORE_ESCAPED=$(echo "$SOLR_CLASSIFICATION_CORE" | sed 's/\//\\\//g')

JDBC_NAME_ESCAPED=$(echo "$JDBC_NAME" | sed 's/\//\\\//g')
JDBC_PASSWORD_ESCAPED=$(echo "$JDBC_PASSWORD" | sed 's/\//\\\//g')
JDBC_DRIVER_ESCAPED=$(echo "$JDBC_DRIVER" | sed 's/\//\\\//g')
JDBC_URL_ESCAPED=$(echo "$JDBC_URL" | sed 's/\//\\\//g')
HIBERNATE_SCHEMA_ESCAPED=$(echo "$JDBC_URL" | sed 's/\//\\\//g')

MYCORE_PROPERTIES="${MCR_CONFIG_DIR}mycore.properties"
PERSISTENCE_XML="${MCR_CONFIG_DIR}resources/META-INF/persistence.xml"

function fixDirectoryRights() {
  find "$1" \! -user "$2" -exec chown "$2:$2" '{}' +
}

echo "Running DEA Starter Script as User: $(whoami)"

if [ "$EUID" -eq 0 ]
  then
    if [[ "$FIX_FILE_SYSTEM_RIGHTS" == "true" ]]
    then
      echo "Fixing File System Rights"
      fixDirectoryRights "$MCR_CONFIG_DIR" "mcr"
      fixDirectoryRights "$MCR_DATA_DIR" "mcr"
      fixDirectoryRights "$MCR_LOG_DIR" "mcr"
    fi
    exec gosu mcr "$0"
    exit 0;
fi

sleep 5 # wait for database (TODO: replace with wait-for-it)

cd /usr/local/tomcat/

function setupLog4jConfig() {
  if [[ ! -f "${MCR_CONFIG_DIR}resources/log4j2.xml" ]]
  then
    cp /opt/dea/log4j2.xml "${MCR_CONFIG_DIR}resources/"
  fi
}

function downloadDriver {
  FILENAME=$(basename $1)
  if [[ ! -f "${MCR_CONFIG_DIR}lib/${FILENAME}" ]]
  then
    curl -o "${MCR_CONFIG_DIR}lib/${FILENAME}" "$1"
  fi
}

function setDockerValues() {
    echo "Set Docker Values to Config!"
    if [ -n "${SOLR_URL}" ]; then
      if grep -q "MCR.Solr.ServerURL=" "${MYCORE_PROPERTIES}" ; then
        sed -ri "s/#?(MCR\.Solr\.ServerURL=).+/\1${SOLR_URL_ESCAPED}/" "${MYCORE_PROPERTIES}";
      else
        echo "MCR.Solr.ServerURL=${SOLR_URL}" >> "${MYCORE_PROPERTIES}";
      fi
    fi

    if [ -n "${SOLR_CORE}" ]; then
      if grep -q "MCR.Solr.Core.main.Name=" "${MYCORE_PROPERTIES}" ; then
        sed -ri "s/#?(MCR\.Solr\.Core\.main\.Name=).+/\1${SOLR_CORE_ESCAPED}/" "${MYCORE_PROPERTIES}";
      else
        echo "MCR.Solr.Core.main.Name=${SOLR_CORE}" >> "${MYCORE_PROPERTIES}";
      fi
    fi

    if [ -n "${SOLR_CLASSIFICATION_CORE}" ]; then
      if grep -q "MCR.Solr.Core.classification.Name=" "${MYCORE_PROPERTIES}" ; then
        sed -ri "s/#?(MCR\.Solr\.Core\.classification\.Name=).+/\1${SOLR_CLASSIFICATION_CORE_ESCAPED}/" "${MYCORE_PROPERTIES}"
      else
        echo "MCR.Solr.Core.classification.Name=${SOLR_CLASSIFICATION_CORE}" >> "${MYCORE_PROPERTIES}";
      fi
    fi

    if [ -n "${JDBC_NAME}" ]; then
      sed -ri "s/(name=\"javax.persistence.jdbc.user\" value=\").*(\")/\1${JDBC_NAME_ESCAPED}\2/" "${PERSISTENCE_XML}"
    fi

    if [ -n "${JDBC_PASSWORD}" ]; then
      sed -ri "s/(name=\"javax.persistence.jdbc.password\" value=\").*(\")/\1${JDBC_PASSWORD_ESCAPED}\2/" "${PERSISTENCE_XML}"
    fi

    if [ -n "${JDBC_DRIVER}" ]; then
      sed -ri "s/(name=\"javax.persistence.jdbc.driver\" value=\").*(\")/\1${JDBC_DRIVER_ESCAPED}\2/" "${PERSISTENCE_XML}"
    fi

    if [ -n "${JDBC_URL}" ]; then
      sed -ri "s/(name=\"javax.persistence.jdbc.url\" value=\").*(\")/\1${JDBC_URL_ESCAPED}\2/" "${PERSISTENCE_XML}"
    fi

    if [ -n "${SOLR_CLASSIFICATION_CORE}" ]; then
      sed -ri "s/(name=\"hibernate.default_schema\" value=\").*(\")/\1${HIBERNATE_SCHEMA_ESCAPED}\2/" "${PERSISTENCE_XML}"
    fi

    sed -ri "s/(name=\"hibernate.hbm2ddl.auto\" value=\").*(\")/\1update\2/" "${PERSISTENCE_XML}"

    if  grep -q "MCR.datadir=" "${MYCORE_PROPERTIES}" ; then
          sed -ri "s/#?(MCR\.datadir=).+/\1${MCR_DATA_DIR_ESCAPED}/" "${MYCORE_PROPERTIES}"
    else
          echo "MCR.datadir=${MCR_DATA_DIR}">>"${MYCORE_PROPERTIES}"
    fi

    if  grep -q "MCR.Save.FileSystem=" "${MYCORE_PROPERTIES}" ; then
          sed -ri "s/#?(MCR\.Save\.FileSystem=).+/\1${MCR_SAVE_DIR_ESCAPED}/" "${MYCORE_PROPERTIES}"
    else
          echo "MCR.Save.FileSystem=${MCR_SAVE_DIR}">>"${MYCORE_PROPERTIES}"
    fi

    case $JDBC_DRIVER in
      org.postgresql.Driver) downloadDriver "https://jdbc.postgresql.org/download/postgresql-42.7.0.jar";;
      org.mariadb.jdbc.Driver) downloadDriver "https://repo.maven.apache.org/maven2/org/mariadb/jdbc/mariadb-java-client/3.3.0/mariadb-java-client-3.3.0.jar";;
      org.h2.Driver) downloadDriver "https://repo1.maven.org/maven2/com/h2database/h2/2.2.224/h2-2.2.224.jar";;
      com.mysql.jdbc.Driver) downloadDriver "https://repo1.maven.org/maven2/com/mysql/mysql-connector-j/8.2.0/mysql-connector-j-8.2.0.jar";;
    esac

    mkdir -p "${MCR_CONFIG_DIR}lib"

    downloadDriver https://repo1.maven.org/maven2/com/zaxxer/HikariCP/5.0.1/HikariCP-5.0.1.jar
    downloadDriver https://repo1.maven.org/maven2/org/hibernate/hibernate-hikaricp/5.6.7.Final/hibernate-hikaricp-5.6.7.Final.jar
}

function setUpMyCoRe {
    echo "Set up MyCoRe!"
    /opt/dea/dea/bin/digital-edition-archive.sh create configuration directory
    setupLog4jConfig
    sed -ri -r 's/(<\/properties>)/<property name=\"hibernate\.connection\.provider_class\" value=\"org\.hibernate\.hikaricp\.internal\.HikariCPConnectionProvider\" \/>\n<property name=\"hibernate\.hikari\.maximumPoolSize\" value=\"30\" \/>\n<property name=\"hibernate\.hikari\.leakDetectionThreshold\" value=\"9000\" \/>\n<property name=\"hibernate\.hikari\.registerMbeans\" value=\"true\" \/>\n\1/' "${PERSISTENCE_XML}"
    setDockerValues
    /opt/dea/dea/bin/digital-edition-archive.sh reload mappings in jpa configuration file
    /opt/dea/dea/bin/digital-edition-archive.sh process resource setup-commands.txt
}

sed -ri "s/(-DMCR.AppName=).+( \\\\)/\-DMCR.ConfigDir=${MCR_CONFIG_DIR_ESCAPED}\2/" /opt/dea/dea/bin/digital-edition-archive.sh
sed -ri "s/(-DMCR.ConfigDir=).+( \\\\)/\-DMCR.ConfigDir=${MCR_CONFIG_DIR_ESCAPED}\2/" /opt/dea/dea/bin/digital-edition-archive.sh

[ "$(ls -A "$MCR_CONFIG_DIR")" ] && setDockerValues || setUpMyCoRe

rm -rf /usr/local/tomcat/webapps/*
cp /opt/dea/dea.war "/usr/local/tomcat/webapps/${APP_CONTEXT}.war"

export JAVA_OPTS="-DMCR.ConfigDir=${MCR_CONFIG_DIR} -Xmx${XMX} -Xms${XMS} -XX:+CrashOnOutOfMemoryError ${APP_OPTS}"
catalina.sh run
