FROM tomcat:10-jdk21-temurin-jammy
RUN groupadd -r mcr -g 501 && \
    useradd -d /home/mcr -u 501 -m -s /bin/bash -g mcr mcr
WORKDIR /usr/local/tomcat/
ARG PACKET_SIZE="65536"
ENV APP_CONTEXT="dea" \
 MCR_CONFIG_DIR="/mcr/home/" \
 MCR_DATA_DIR="/mcr/data/" \
 MCR_LOG_DIR="/mcr/logs/" \
 SOLR_CORE="dea" \
 SOLR_CLASSIFICATION_CORE="dea-classifications" \
 XMX="1g" \
 XMS="1g"
#COPY --from=regreb/bibutils --chown=mcr:mcr /usr/local/bin/* /usr/local/bin/
COPY --chown=root:root docker-entrypoint.sh /usr/local/bin/dea.sh

RUN set -eux; \
    chmod 555 /usr/local/bin/dea.sh; \
	apt-get update; \
	apt-get install -y gosu; \
    apt-get install -y postgresql-client; \
	rm -rf /var/lib/apt/lists/*;
RUN rm -rf /usr/local/tomcat/webapps/* && \
    mkdir /opt/dea/ && \
    chown mcr:mcr -R /opt/dea/ && \
    sed -ri "s/<\/Service>/<Connector protocol=\"AJP\/1.3\" packetSize=\"$PACKET_SIZE\" tomcatAuthentication=\"false\" scheme=\"https\" secretRequired=\"false\" allowedRequestAttributesPattern=\".*\" encodedSolidusHandling=\"passthrough\" address=\"0.0.0.0\" port=\"8009\" redirectPort=\"8443\" \/>&/g" /usr/local/tomcat/conf/server.xml
COPY --chown=mcr:mcr digital-edition-archive-webapp/target/digital-edition-archive-*.war /opt/dea/dea.war
COPY --chown=mcr:mcr digital-edition-archive-cli/target/digital-edition-archive-cli-*.tar.gz /opt/dea/dea.tar.gz
COPY --chown=mcr:mcr docker-log4j2.xml /opt/dea/log4j2.xml
RUN cd /opt/dea/ &&  \
    tar -zxf /opt/dea/dea.tar.gz && \
    /bin/sh -c "mv digital-edition-archive-* dea" && \
    chown mcr:mcr -R /opt/dea/ /usr/local/tomcat/webapps/
CMD ["bash", "/usr/local/bin/dea.sh"]
