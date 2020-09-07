FROM openjdk:8-alpine
MAINTAINER Ingo Müller <ingo.mueller@inf.ethz.ch>

ARG SPARK_VERSION=2.4.6
ARG RUMBLE_VERSION=1.8.0

ENV SPARK_HOME=/opt/spark
ENV SPARK_WORKER_DIR=/var/spark

RUN adduser -Ds /bin/bash -h ${SPARK_WORKER_DIR} spark && \
    apk add --no-cache bash tini libc6-compat linux-pam krb5 krb5-libs && \
# Download Spark
    apk add --virtual .deps --no-cache wget tar && \
    mkdir /opt/spark && \
    cd /opt/spark && \
    wget --progress=dot:giga https://archive.apache.org/dist/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-hadoop2.7.tgz -O - | \
        tar -zx --strip-components 1 && \
# Download Rumble
    suffix=$(if [[ "${SPARK_VERSION:0:1}" -eq 3 ]]; then echo -for-spark-3; fi) && \
    wget --progress=dot:giga -O /opt/spark/jars/spark-rumble-jar-with-dependencies.jar \
        https://github.com/RumbleDB/rumble/releases/download/v${RUMBLE_VERSION}/spark-rumble-${RUMBLE_VERSION}${suffix}.jar && \
# Clean-up
    apk --no-cache del .deps

WORKDIR ${SPARK_WORKER_DIR}
USER spark:spark
ENTRYPOINT [ "/opt/spark/bin/spark-submit", "/opt/spark/jars/spark-rumble-jar-with-dependencies.jar" ]
