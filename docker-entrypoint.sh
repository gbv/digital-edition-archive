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
HIBERNATE_SCHEMA="${HIBERNATE_SCHEMA:-public}"
HIBERNATE_SCHEMA_ESCAPED=$(echo "$HIBERNATE_SCHEMA" | sed 's/\//\\\//g')

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

# Function to parse a JDBC URL (including type) and output assignments for eval
# Usage: eval "$(parse_jdbc_url_eval "jdbc:...")"
parse_jdbc_url_eval() {
  local url_string="$1"
  local type=""
  local host=""
  local port=""
  local database=""
  local regex="^jdbc:([^:]+)://([^:/]+)(:([0-9]+))?/([^?]+)(.*)?$"

  echo "type="; echo "host="; echo "port="; echo "database=" # Clear vars

  if [[ -z "$url_string" ]]; then
    echo "Error: No JDBC URL provided for parsing." >&2
    return 1
  fi

  if [[ "$url_string" =~ $regex ]]; then
    type="${BASH_REMATCH[1]}"
    host="${BASH_REMATCH[2]}"
    port="${BASH_REMATCH[4]}"
    database="${BASH_REMATCH[5]}"

    printf "type=%q\n" "$type"
    printf "host=%q\n" "$host"
    printf "port=%q\n" "$port"
    printf "database=%q\n" "$database"
    return 0
  else
    echo "Error: Failed to parse JDBC URL: $url_string" >&2
    return 1
  fi
}

# Function to check PostgreSQL database readiness using psql
# Usage: check_psql_ready <jdbc_url> <username> <password> [retries] [delay_seconds]
# Example: check_psql_ready "jdbc:postgresql://db:5432/dea" "user" "pass" 10 5
check_psql_ready() {
  local jdbc_url="$1"
  local jdbc_user="$2"
  local jdbc_password="$3"
  local retries="${4:-10}" # Default to 10 retries if not provided
  local delay="${5:-5}"    # Default to 5 seconds delay if not provided

  local type="" host="" port="" database=""
  local exit_code=1 # Default to failure

  echo "Attempting to parse JDBC URL: $jdbc_url"
  # Use eval to get variables (type, host, port, database)
  if ! eval "$(parse_jdbc_url_eval "$jdbc_url")"; then
    echo "ERROR: Could not parse JDBC URL. Cannot proceed." >&2
    return 1
  fi

  # --- Validate parsed components and type ---
  if [[ -z "$type" ]] || [[ -z "$host" ]] || [[ -z "$database" ]]; then
     echo "ERROR: Parsing URL failed to extract essential components (type, host, database)." >&2
     echo "Type: '$type', Host: '$host', Port: '$port', Database: '$database'" >&2
     return 1
  fi

  if [[ "$type" != "postgresql" ]]; then
      echo "Unsupported database type '$type'. This function only supports 'postgresql'. Assume db is ready..." >&2
      return 0
  fi

  echo "Parsed details - Type: $type, Host: $host, Port: $port, Database: $database"

  # --- Build psql command ---
  local port_num="$port"
  # Use default PostgreSQL port if not specified
  [[ -z "$port_num" ]] && port_num="5432"

  # Use \q for a quick connection test without running a query
  # -qtA = Quiet, Tuples only, Align off (minimal output)
  # -w = Never issue password prompt (relies on PGPASSWORD)
  # --host, --port, --username, --dbname are explicit ways to pass parameters
  local connect_cmd="psql --host=\"$host\" --port=\"$port_num\" --username=\"$JDBC_NAME\" --dbname=\"$database\" --no-password --quiet --tuples-only --no-align --command='\\q'"
  local password_env_var="PGPASSWORD"

  echo "Using psql command: $connect_cmd"
  echo "Starting check loop ($retries retries, $delay seconds delay)..."

  for (( i=1; i<=retries; i++ )); do
    echo "Attempt $i of $retries: Connecting to PostgreSQL database '$database' on $host:$port_num..."

    # Safely pass the password via environment variable in a subshell
    (export "$password_env_var=$JDBC_PASSWORD"; eval "$connect_cmd") > /dev/null 2>&1
    exit_code=$?

    if [[ $exit_code -eq 0 ]]; then
      echo "SUCCESS: PostgreSQL connection established."
      return 0 # Success!
    else
      echo "WARN: Connection failed (Exit code: $exit_code)."
      if (( i < retries )); then
        echo "Retrying in $delay seconds..."
        sleep "$delay"
      fi
    fi
  done

  echo "ERROR: PostgreSQL connection failed after $retries attempts." >&2
  return 1 # Failure after all retries
}

execute_psql_command() {
    local jdbc_url="$1"
    local jdbc_user="$2"
    local jdbc_password="$3"
    local sql_command_to_run="$4" # Renamed to avoid potential clash

    local type="" host="" port="" database=""
    local psql_exit_code=1

    echo "Attempting to parse JDBC URL for SQL execution: $jdbc_url"
    local parse_output
    parse_output=$(parse_jdbc_url_eval "$jdbc_url")
    local parse_status=$?

    if [[ $parse_status -ne 0 ]]; then
        echo "ERROR: Could not parse JDBC URL in execute_psql_command." >&2
        return 1
    fi
    eval "$parse_output" # Set local type, host, port, database

    # --- Validate parsed components and type ---
    if [[ -z "$type" ]] || [[ -z "$host" ]] || [[ -z "$database" ]]; then
        echo "ERROR: Parsing URL failed to extract essential components for execution." >&2
        echo "Type: '$type', Host: '$host', Port: '$port', Database: '$database'" >&2
        return 1
    fi

    if [[ "$type" != "postgresql" ]]; then
        echo "WARN: Unsupported database type '$type'. This function only supports 'postgresql'. Continue.." >&2
        return 0
    fi

    if [[ -z "$sql_command_to_run" ]]; then
        echo "ERROR: No SQL command provided to execute." >&2
        return 1
    fi

    local port_num="$port"
    [[ -z "$port_num" ]] && port_num="5432" # Use default PostgreSQL port

    echo "Executing SQL on $host:$port_num/$database:"
    # Print command indented for clarity, handle potential newlines safely
    echo "--- SQL Start ---"
    printf "%s\n" "$sql_command_to_run" | sed 's/^/  /' # Indent multi-line SQL
    echo "--- SQL End ---"

    # Build the psql command
    # -v ON_ERROR_STOP=1 : Exit script on SQL error
    local psql_exec_cmd="psql --host=\"$host\" \
                             --port=\"$port_num\" \
                             --username=\"$jdbc_user\" \
                             --dbname=\"$database\" \
                             --no-password \
                             -v ON_ERROR_STOP=1 \
                             --command=\"$sql_command_to_run\""

    # Execute in a subshell with PGPASSWORD set
    # Output is NOT redirected - allows seeing results or errors from psql
    ( export PGPASSWORD="$jdbc_password"; eval "$psql_exec_cmd" )
    psql_exit_code=$?

    if [[ $psql_exit_code -eq 0 ]]; then
        echo "SUCCESS: SQL command executed successfully."
        return 0 # Success
    else
        # Error message already printed by psql due to ON_ERROR_STOP
        echo "ERROR: Failed to execute SQL command (Exit code: $psql_exit_code)." >&2
        return 1 # Failure
    fi
}

function migrate_user_table_2023_2024() {
    echo "Run migration script: migrate_user_table_2023_2024"
    local migration_script="alter table ${HIBERNATE_SCHEMA}.mcruser drop constraint if exists mcruser_hashtype_check;"
    # Call the execution function
    if execute_psql_command "$JDBC_URL" "$JDBC_NAME" "$JDBC_PASSWORD" "$migration_script"; then
      echo "Migration SQL command succeeded."
    else
      echo "ERROR: SQL command failed. Exiting." >&2
      exit 1 # Exit script if the post-ready command fails
    fi
}

function mcrjobparameter_2023_2024() {
    echo "Run migration script: mcrjobparameter_2023_2024"
    local migration_script="alter table  ${HIBERNATE_SCHEMA}.mcrjobparameter alter column paramvalue set data type varchar(16384);"
    if execute_psql_command "$JDBC_URL" "$JDBC_NAME" "$JDBC_PASSWORD" "$migration_script"; then
      echo "Migration SQL command succeeded."
    else
      echo "ERROR: SQL command failed. Exiting." >&2
      exit 1 # Exit script if the post-ready command fails
    fi
}

function setOrAddProperty() {
    KEY=$1
    VALUE=$2

    if [ -z "$VALUE" ]; then
      # remove property
      sed -ri "/$KEY/d" "${MYCORE_PROPERTIES}"
      return
    elif [ -z "$KEY" ]; then
      echo "No Key given. Skip setting property."
      return
    fi

    if grep -q "$KEY=" "${MYCORE_PROPERTIES}" ; then
      ESCAPED_KEY=$(echo "${KEY}" | sed 's/\//\\\//g')
      ESCAPED_VALUE=$(echo "${VALUE}" | sed 's/\//\\\//g')
      sed -ri "s/#*($ESCAPED_KEY=).+/\1$ESCAPED_VALUE/" "${MYCORE_PROPERTIES}"
    else
      echo "$KEY=$VALUE">>"${MYCORE_PROPERTIES}"
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
      setOrAddProperty "MCR.JPA.User" "${JDBC_NAME}"
    fi

    if [ -n "${JDBC_PASSWORD}" ]; then
      setOrAddProperty "MCR.JPA.Password" "${JDBC_PASSWORD}"
    fi

    if [ -n "${JDBC_DRIVER}" ]; then
      setOrAddProperty "MCR.JPA.Driver" "${JDBC_DRIVER}"
    fi

    if [ -n "${JDBC_URL}" ]; then
      setOrAddProperty "MCR.JPA.URL" "${JDBC_URL}"
    fi

    if [ -n "${HIBERNATE_SCHEMA}" ]; then
      setOrAddProperty "MCR.JPA.DefaultSchema" "${HIBERNATE_SCHEMA}"
    fi

    if [ -n "${SOLR_CLASSIFICATION_CORE}" ]; then
      sed -ri "s/(name=\"hibernate.default_schema\" value=\").*(\")/\1${HIBERNATE_SCHEMA_ESCAPED}\2/" "${PERSISTENCE_XML}"
    fi

    setOrAddProperty "MCR.JPA.Hbm2ddlAuto" "update"
    setOrAddProperty "MCR.JPA.PersistenceUnit.dea.Class" "org.mycore.backend.jpa.MCRSimpleConfigPersistenceUnitDescriptor"
    setOrAddProperty "MCR.JPA.PersistenceUnitName" "dea"

    setOrAddProperty "MCR.datadir" "${MCR_DATA_DIR}"
    setOrAddProperty "MCR.Solr.NestedDocuments" "true"
    setOrAddProperty "MCR.Save.FileSystem" "${MCR_SAVE_DIR}"

    setOrAddProperty "MCR.JPA.Connection.ProviderClass" "org.hibernate.hikaricp.internal.HikariCPConnectionProvider"
    setOrAddProperty "MCR.JPA.Connection.MaximumPoolSize" "30"
    setOrAddProperty "MCR.JPA.Connection.MinimumIdle" "2"
    setOrAddProperty "MCR.JPA.Connection.IdleTimeout" "30000"
    setOrAddProperty "MCR.JPA.Connection.MaxLifetime" "180000"
    setOrAddProperty "MCR.JPA.Connection.LeakDetectionThreshold" "9000"
    setOrAddProperty "MCR.JPA.Connection.RegisterMbeans" "true"

    case $JDBC_DRIVER in
      org.postgresql.Driver) downloadDriver "https://jdbc.postgresql.org/download/postgresql-42.7.0.jar";;
      org.mariadb.jdbc.Driver) downloadDriver "https://repo.maven.apache.org/maven2/org/mariadb/jdbc/mariadb-java-client/3.3.0/mariadb-java-client-3.3.0.jar";;
      org.h2.Driver) downloadDriver "https://repo1.maven.org/maven2/com/h2database/h2/2.2.224/h2-2.2.224.jar";;
      com.mysql.jdbc.Driver) downloadDriver "https://repo1.maven.org/maven2/com/mysql/mysql-connector-j/8.2.0/mysql-connector-j-8.2.0.jar";;
    esac

    mkdir -p "${MCR_CONFIG_DIR}lib"

    downloadDriver https://repo1.maven.org/maven2/com/zaxxer/HikariCP/5.1.0/HikariCP-5.1.0.jar
    downloadDriver https://repo1.maven.org/maven2/org/hibernate/orm/hibernate-hikaricp/6.3.1.Final/hibernate-hikaricp-6.3.1.Final.jar

    rm -f "${PERSISTENCE_XML}"
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


if check_psql_ready "$JDBC_URL" "$JDBC_NAME" "$JDBC_PASSWORD" 5 3; then
  echo "Database is ready. Proceeding..."
else
  echo "Database readiness check failed. Exiting."
  exit 1
fi

# check if migration scripts should be run
if [[ "$RUN_MIGRATION_SCRIPTS" == "true" ]]; then
  echo "Running migration scripts..."
  migrate_user_table_2023_2024
  mcrjobparameter_2023_2024
else
  echo "Skipping migration scripts."
fi

[ "$(ls -A "$MCR_CONFIG_DIR")" ] && setDockerValues || setUpMyCoRe

rm -rf /usr/local/tomcat/webapps/*
cp /opt/dea/dea.war "/usr/local/tomcat/webapps/${APP_CONTEXT}.war"

export JAVA_OPTS="-DMCR.ConfigDir=${MCR_CONFIG_DIR} -Xmx${XMX} -Xms${XMS} -XX:+CrashOnOutOfMemoryError ${APP_OPTS}"
catalina.sh run
