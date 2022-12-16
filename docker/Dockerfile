FROM openjdk:8-alpine
MAINTAINER Ingo Müller <ingo.mueller@inf.ethz.ch>

ARG SPARK_URL
ARG RUMBLEDB_URL

ENV SPARK_HOME=/opt/spark
ENV SPARK_WORKER_DIR=/var/spark

RUN adduser -Ds /bin/bash -h ${SPARK_WORKER_DIR} spark && \
    apk add --no-cache \
        bash \
	krb5 \
	krb5-libs \
	libc6-compat \
	linux-pam \
	procps \
	tini \
	&& \
    ln -s /lib/libc.musl-x86_64.so.1 /lib/ld-linux-x86-64.so.2 && \
# Download Spark
    apk add --virtual .deps --no-cache wget tar && \
    mkdir /opt/spark && \
    cd /opt/spark && \
    ( \
        wget --progress=dot:giga ${SPARK_URL} -O - || \
        wget --progress=dot:giga $(echo ${SPARK_URL} | sed "s~^https://downloads.apache.org/spark/~https://archive.apache.org/dist/spark/~") -O - \
    ) | tar -zx --strip-components 1 && \
# Download Rumble
    wget --progress=dot:giga -O /opt/spark/jars/spark-rumble-jar-with-dependencies.jar \
        ${RUMBLEDB_URL} && \
# Clean-up
    apk --no-cache del .deps

COPY entrypoint.sh "/opt/entrypoint.sh"
WORKDIR ${SPARK_WORKER_DIR}
USER spark:spark
ENTRYPOINT [ "/opt/entrypoint.sh" ]
