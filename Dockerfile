FROM openjdk:8-alpine
MAINTAINER Ingo Müller <ingo.mueller@inf.ethz.ch>

ENV SPARK_HOME=/opt/spark
ENV SPARK_WORKER_DIR=/var/spark

RUN adduser -Ds /bin/bash -h ${SPARK_WORKER_DIR} spark && \
    apk add --no-cache bash tini libc6-compat linux-pam krb5 krb5-libs && \
# Download Spark
    apk add --virtual .deps --no-cache wget tar && \
    mkdir /opt/spark && \
    cd /opt/spark && \
    version=2.4.6 && \
    wget --progress=dot:giga http://apache.uvigo.es/spark/spark-${version}/spark-${version}-bin-hadoop2.7.tgz -O - | \
        tar -zx --strip-components 1 && \
# Download Rumble
    cd /opt/spark/jars && \
    version=1.7.0 && \
    wget --progress=dot:giga https://github.com/RumbleDB/rumble/releases/download/v${version}/spark-rumble-${version}.jar -O spark-rumble.jar && \
# Clean-up
    apk --no-cache del .deps && \
    rm -rf /tmp/*

WORKDIR ${SPARK_WORKER_DIR}
USER spark:spark
ENTRYPOINT [ "/opt/spark/bin/spark-submit", "/opt/spark/jars/spark-rumble.jar" ]
