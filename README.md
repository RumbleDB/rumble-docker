# Docker Images for RumbleDB

This repository hosts the scripts to build the [official docker images](https://hub.docker.com/repository/docker/rumbledb/rumble) for [RumbleDB](https://rumbledb.org/).

# How to Use the Image

The most simple command is the following, which starts the RumbleDB shell in a docker container that is destroyed after exit:

```bash
docker run --rm -it rumbledb/rumble --shell yes
```

Instead of `--shell yes`, any other command line parameters of RumbleDB can be used and vary across versions.

It is possible to pass in command line parameters to `spark-submit` via the environment variable `SPARK_SUBMIT_OPTIONS`:

```bash
docker run --rm -it -e "SPARK_SUBMIT_OPTIONS=--master local[2]" rumbledb/rumble --shell yes
```

# Tags on Docker Hub

We maintain the following tags on Docker Hub:

* `latest`: Latest version of RumbleDB with the latest version of Spark.
* `spark2`/`spark3`: Latest version of RumbleDB with the latest compatible version of Spark 2/3.
* `<version>`: Specific version of RumblDB with the latest compatible version of Spark.
* `<version>-spark2`/`<version>-spark3`: Specific version of RumbleDB with the latest compatible version of Spark 2/3.
