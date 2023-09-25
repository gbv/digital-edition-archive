FROM solr:8.11
USER root
RUN apt-get update && \
    apt-get -y install git sudo && \
    git clone https://github.com/MyCoRe-Org/mycore_solr_configset_main.git && \
    git clone https://github.com/MyCoRe-Org/mycore_solr_configset_classification.git && \
    mkdir -p /opt/solr/server/solr/configsets/ && \
    cp -r mycore_solr_configset_main /opt/solr/server/solr/configsets/mycore_main && \
    cp -r mycore_solr_configset_classification /opt/solr/server/solr/configsets/mycore_classification && \
    chown -R solr:solr /opt/solr/server/solr/configsets/mycore_main && \
    chown -R solr:solr /opt/solr/server/solr/configsets/mycore_classification  && \
    rm -rf /opt/solr/server/solr/configsets/mycore_main/.git && \
    rm -rf /opt/solr/server/solr/configsets/mycore_classification/.git
COPY --chown=root:root docker-entrypoint.sh ./
RUN sed -ri 's/ class="solr.[Fast]*LRUCache"//' /opt/solr/server/solr/configsets/mycore_main/conf/solrconfig.xml && \
    sed -ri 's/ class="solr.[Fast]*LRUCache"//' /opt/solr/server/solr/configsets/mycore_classification/conf/solrconfig.xml && \
    chmod 555 docker-entrypoint.sh
CMD ["bash", "docker-entrypoint.sh"]