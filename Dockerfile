FROM openjdk:8-alpine
MAINTAINER Ingo Müller <ingo.mueller@inf.ethz.ch>

ARG SPARK_VERSION=3.1.2
ARG RUMBLE_FILENAME=v1.16.2/rumbledb-1.16.2-for-spark-3.2.jar

ENV SPARK_HOME=/opt/spark
ENV SPARK_WORKER_DIR=/var/spark

RUN adduser -Ds /bin/bash -h ${SPARK_WORKER_DIR} spark && \
    apk add --no-cache bash tini libc6-compat linux-pam krb5 krb5-libs && \
    ln -s /lib/libc.musl-x86_64.so.1 /lib/ld-linux-x86-64.so.2 && \
# Download Spark
    apk add --virtual .deps --no-cache wget tar && \
    mkdir /opt/spark && \
    cd /opt/spark && \
    wget --progress=dot:giga https://downloads.apache.org/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-hadoop2.7.tgz -O - | \
        tar -zx --strip-components 1 && \
# Download Rumble
    wget --progress=dot:giga -O /opt/spark/jars/spark-rumble-jar-with-dependencies.jar \
        https://github.com/RumbleDB/rumble/releases/download/${RUMBLE_FILENAME} && \
# Clean-up
    apk --no-cache del .deps

COPY entrypoint.sh "/opt/entrypoint.sh"
WORKDIR ${SPARK_WORKER_DIR}
USER spark:spark
ENTRYPOINT [ "/opt/entrypoint.sh" ]
