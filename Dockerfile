FROM registry.access.redhat.com/ubi8/openjdk-11

USER root

ENV OC_VERSION=4.13

COPY runTest.sh /opt/runTest.sh
COPY imageStream.yaml /opt/imageStream.yaml
COPY nexusImageStream.yaml /opt/nexusImageStream.yaml
COPY private.properties /opt/private.properties

RUN microdnf -y update && \
    microdnf -y install tar gzip git wget && microdnf clean all
RUN wget https://mirror.openshift.com/pub/openshift-v4/clients/ocp/fast-${OC_VERSION}/openshift-client-linux.tar.gz \
    -O /tmp/openshift-client.tar.gz &&\
    tar xzf /tmp/openshift-client.tar.gz -C /usr/bin oc &&\
    rm /tmp/openshift-client.tar.gz

## Add permission for runTest.sh script so it can be exacuted in container run
RUN chmod 755 /opt/runTest.sh

CMD [ "/opt/runTest.sh" ]