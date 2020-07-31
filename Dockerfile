# Make the base image configurable:
ARG BASEIMAGE=gitlab-registry.cern.ch/treemaker/treemaker/treemaker:Run2_2017-standalone

# Set up the CMSSW base:
FROM ${BASEIMAGE}

ARG BUILD_DATE
ARG VCS_REF
ARG VCS_URL
ARG VERSION
LABEL   org.label-schema.build-date=$BUILD_DATE \
        org.label-schema.name="TreeMaker Docker image for ServiceX" \
        org.label-schema.description="Provide completely offline-runnable CMSSW images with the TreeMaker and ServiceX dependencies pre-installed." \
        org.label-schema.url="https://github.com/TreeMaker/ServiceX-Transformer" \
        org.label-schema.vcs-ref=$VCS_REF \
        org.label-schema.vcs-url=$VCS_URL \
        org.label-schema.vendor="FNAL" \
        org.label-schema.version=$VERSION \
        org.label-schema.schema-version="1.0"

USER    cmsusr
WORKDIR /home/cmsusr

ARG CMSSW_VERSION=CMSSW_10_2_21
ARG DOWNLOAD_URL
ARG FILE_NAME

RUN git clone https://github.com/TreeMaker/ServiceX-Transformer.git && \
    ${HOME}/ServiceX-Transformer/scripts/setup.sh -c $CMSSW_VERSION -f $FILE_NAME -u $DOWNLOAD_URL && \
    rm -rf ${HOME}/ServiceX-Transformer

ENTRYPOINT ["/bin/zsh"]
