# Docker Images for RumbleDB

This repository hosts the scripts to build the [official docker images](https://hub.docker.com/repository/docker/rumbledb/rumble) for [RumbleDB](https://rumbledb.org/).

## How to Use the Image

The most simple command is the following, which starts the RumbleDB shell in a docker container that is destroyed after exit:

```bash
docker run --rm -it rumbledb/rumble --shell yes
```

Instead of `--shell yes`, any other command line parameters of RumbleDB can be used and vary across versions.

It is possible to pass in command line parameters to `spark-submit` via the environment variable `SPARK_SUBMIT_OPTIONS`:

```bash
docker run --rm -it -e "SPARK_SUBMIT_OPTIONS=--master local[2]" rumbledb/rumble --shell yes
```

## Tags on Docker Hub

We maintain the following tags on Docker Hub:

* `latest`: Latest version of RumbleDB with the latest version of Spark.
* `spark2`/`spark3`: Latest version of RumbleDB with the latest compatible version of Spark 2/3.
* `<version>`: Specific version of RumblDB with the latest compatible version of Spark.
* `<version>-spark2`/`<version>-spark3`: Specific version of RumbleDB with the latest compatible version of Spark 2/3.

## Building the Image

### Locally

The [`tools/build.sh`](tools/build.sh) script makes it easy to build the Docker images yourself. The only mandatory parameter is the version number of RumbleDB:

```bash
tools/build.sh -r 1.20.0
```

The script makes a best effort to derive the required versions of Spark and Hadoop from the version of RumbleDB, as well as the URLs of the respective packages and the tag of the resulting Docker image. All of these can be overwritten, though, as the usage message indicates:

```
Usage:
  tools/build.sh \
      (-r RUMBLEDB_VERSION | -R RUMBLEDB_URL) \
      [-s SPARK_VERSION | -S SPARK_URL] \
      [-h SPARK_HADOOP_VERSION) \
      [-t DOCKER_TAG]
```

### Releasing new Versions

The script has hard-coded information for the latest compatible version of Spark as well as the URLs of the packages. This information needs to be extended for new versions of RumbleDB and/or new versions of Spark.

#### New Version of RumbleDB

The script needs to be extended in the following places:

1. The `SPARK_VERSIONS` needs to be extended with a new entry with the new version of RumbleDB.
1. The `RUMBLE_FILENAMES` array needs to be extended with new entries for each version of Spark supported by the new version of RumbleDB.

#### New Minor Versions of Spark

The `SPARK_VERSIONS` array needs to be modified to reflect the minor version updates.

#### Releasing the New Images to Docker Hub

1. Extend and modify the script as described above.
1. Build all images for the versions that are affected by changes to the script.
1. After a quick test, commit the changes and push them to this repository.
1. Add all convenience [tags](https://docs.docker.com/engine/reference/commandline/tag/) (`<version>`, `spark2`, `spark3`, `latest`) that have updated. For example:

   ```bash
   docker tag rumbledb/rumble:v1.20.0-spark3 rumbledb/rumble:v1.20.0
   docker tag rumbledb/rumble:v1.20.0-spark3 rumbledb/rumble:spark3
   docker tag rumbledb/rumble:v1.20.0-spark3 rumbledb/rumble:latest
   ```

1. [Push](https://docs.docker.com/engine/reference/commandline/push/) all new tags to the Docker Hub:

   ```bash
   docker push rumbledb/rumble:v1.20.0
   docker push rumbledb/rumble:spark3
   docker push rumbledb/rumble:latest
   ```
