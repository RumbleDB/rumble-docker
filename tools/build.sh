#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

#
# Parse command line parameters.
#
print_usage() {
  cat - 1>&2 <<-EOF
		Usage:
		  $0 \\
		      (-r RUMBLEDB_VERSION | -R RUMBLEDB_URL) \\
		      [-s SPARK_VERSION | -S SPARK_URL] \\
		      [-h SPARK_HADOOP_VERSION) \\
		      [-t DOCKER_TAG]
		EOF
  exit 1
}

# Parse options.
while getopts ":r:R:s:S:t:" o
do
  case "${o}" in
    r)
      rumble_version=${OPTARG}
      ;;
    R)
      rumble_url=${OPTARG}
      ;;
    s)
      spark_version=${OPTARG}
      ;;
    S)
      spark_url=${OPTARG}
      ;;
    t)
      docker_tag=${OPTARG}
      ;;
    *)
      print_usage
      ;;
  esac
done
shift $((OPTIND-1))

if [[ "$#" -ne 0 || -z "$rumble_version$rumble_url" ]]
then
  print_usage
fi

#
# Parse RumbleDB version.
#

if [[ -n "$rumble_version" ]]
then
  IFS='.' read -ra rumble_version_components <<< "$rumble_version"
  if [[ ${#rumble_version_components[@]} -ne 3 ]]
  then
    echo "Could not parse RumbleDB version: $rumble_version" 2>&1
    exit 1
  fi
  rumble_major=${rumble_version_components[0]}
  rumble_minor=${rumble_version_components[1]}
  rumble_patch=${rumble_version_components[2]}
fi

#
# Parse Spark version.
#

declare -A SPARK_VERSIONS=(
  [1.6.4]=2.4.8
  [1.7.0]=3.0.3
  [1.8.0]=3.0.3
  [1.8.1]=3.0.3
  [1.9.0]=3.0.3
  [1.9.1]=3.0.3
  [1.10.0]=3.0.3
  [1.11.0]=3.0.3
  [1.12.0]=3.0.3
  [1.14.0]=3.0.3
  [1.15.0]=3.0.3
  [1.16.0]=3.0.3
  [1.16.1]=3.2.3
  [1.16.2]=3.2.3
  [1.17.0]=3.2.3
  [1.18.0]=3.2.3
  [1.19.0]=3.3.1
  [1.20.0]=3.3.1
)

if [[ -z "$spark_version" && -n "$rumble_version" ]]
then
  echo "Automatically selecting Spark version based on RumbleDB version..."
  spark_version=${SPARK_VERSIONS[$rumble_version]}
fi

if [[ -n "$spark_version" ]]
then
  IFS='.' read -ra spark_version_components <<< "$spark_version"
  if [[ ${#spark_version_components[@]} -ne 3 ]]
  then
    echo "Could not parse Spark version: $spark_version" 2>&1
    exit 1
  fi
  spark_major=${spark_version_components[0]}
  spark_minor=${spark_version_components[1]}
  spark_patch=${spark_version_components[2]}
fi

#
# Parse Hadoop version.
#

if [[ -z "$hadoop_version" && -n "$spark_version" ]]
then
  echo "Automatically selecting Hadoop version based on Spark version..."
  hadoop_version=2.7
  if [[ $spark_major -ge 3 ]]
  then
    hadoop_version=3.2
  fi
fi

#
# Assemble Spark URL.
#

if [[ -z "$spark_url" && -n "$spark_version" && -n "$hadoop_version" ]]
then
  echo "Automatically deriving Spark URL..."

  hadoop_version_string=$hadoop_version

  # Hadoop minor version is dropped for Spark >= 3.3.0.*
  if [[ "$spark_version" == "3.3."* || "$spark_major" -gt 3 ]]
  then
    hadoop_version_string=${hadoop_version:0:1}
  fi

  spark_url="https://downloads.apache.org/spark/spark-${spark_version}/spark-${spark_version}-bin-hadoop${hadoop_version_string}.tgz"
fi

#
# Assemble Rumble URL.
#

declare -A RUMBLE_FILENAMES=(
  [1.6.4-2.4]=v1.6.4/spark-rumble-1.6.4.jar
  [1.7.0-2.4]=v1.7.0/spark-rumble-1.7.0.jar
  [1.7.0-3.0]=v1.7.0/spark-rumble-1.7.0-for-spark-3.jar
  [1.8.0-2.4]=v1.8.0/spark-rumble-1.8.0.jar
  [1.8.0-3.0]=v1.8.0/spark-rumble-1.8.0-for-spark-3.jar
  [1.8.1-2.4]=v1.8.1/spark-rumble-1.8.1.jar
  [1.8.1-3.0]=v1.8.1/spark-rumble-1.8.1-for-spark-3.jar
  [1.9.0-2.4]=v1.9.0/spark-rumble-1.9.0.jar
  [1.9.0-3.0]=v1.9.0/spark-rumble-1.9.0-for-spark-3.jar
  [1.9.1-2.4]=v1.9.1/spark-rumble-1.9.1.jar
  [1.9.1-3.0]=v1.9.1/spark-rumble-1.9.1-for-spark-3.jar
  [1.10.0-2.4]=v1.10.0/spark-rumble-1.10.0-for-spark-2.jar
  [1.10.0-3.0]=v1.10.0/spark-rumble-1.10.0.jar
  [1.11.0-2.4]=v1.11.0/spark-rumble-1.11.0-for-spark-2.jar
  [1.11.0-3.0]=v1.11.0/spark-rumble-1.11.0.jar
  [1.12.0-2.4]=v1.12.0/spark-rumble-1.12.0-for-spark-2.jar
  [1.12.0-3.0]=v1.12.0/spark-rumble-1.12.0.jar
  [1.14.0-2.4]=v1.14.0/rumbledb-1.14.0-for-spark-2.jar
  [1.14.0-3.0]=v1.14.0/rumbledb-1.14.0.jar
  [1.15.0-2.4]=v1.15.0/rumbledb-1.15.0-for-spark-2.jar
  [1.15.0-3.0]=v1.15.0/rumbledb-1.15.0.jar
  [1.16.0-2.4]=v1.16.0/rumbledb-1.16.0-for-spark-2.jar
  [1.16.0-3.0]=v1.16.0/rumbledb-1.16.0-for-spark-3.0.jar
  [1.16.1-2.4]=v1.16.1/rumbledb-1.16.1-for-spark-2.4.jar
  [1.16.1-3.0]=v1.16.1/rumbledb-1.16.1-for-spark-3.0.jar
  [1.16.1-3.1]=v1.16.1/rumbledb-1.16.1-for-spark-3.1.jar
  [1.16.1-3.2]=v1.16.1/rumbledb-1.16.1-for-spark-3.2.jar
  [1.16.2-2.4]=v1.16.2/rumbledb-1.16.2-for-spark-2.4.jar
  [1.16.2-3.0]=v1.16.2/rumbledb-1.16.2-for-spark-3.0.jar
  [1.16.2-3.1]=v1.16.2/rumbledb-1.16.2-for-spark-3.1.jar
  [1.16.2-3.2]=v1.16.2/rumbledb-1.16.2-for-spark-3.2.jar
  [1.17.0-2.4]=v1.17.0/rumbledb-1.17.0-for-spark-2.4.jar
  [1.17.0-3.0]=v1.17.0/rumbledb-1.17.0-for-spark-3.0.jar
  [1.17.0-3.1]=v1.17.0/rumbledb-1.17.0-for-spark-3.1.jar
  [1.17.0-3.2]=v1.17.0/rumbledb-1.17.0-for-spark-3.2.jar
  [1.18.0-3.0]=v1.18.0/rumbledb-1.18.0-for-spark-3.0.jar
  [1.18.0-3.1]=v1.18.0/rumbledb-1.18.0-for-spark-3.1.jar
  [1.18.0-3.2]=v1.18.0/rumbledb-1.18.0-for-spark-3.2.jar
  [1.19.0-3.0]=v1.19.0/rumbledb-1.19.0-for-spark-3.0.jar
  [1.19.0-3.1]=v1.19.0/rumbledb-1.19.0-for-spark-3.1.jar
  [1.19.0-3.2]=v1.19.0/rumbledb-1.19.0-for-spark-3.2.jar
  [1.19.0-3.3]=v1.19.0/rumbledb-1.19.0-for-spark-3.3.jar
  [1.20.0-3.1]=v1.20.0/rumbledb-1.20.0-for-spark-3.1.jar
  [1.20.0-3.2]=v1.20.0/rumbledb-1.20.0-for-spark-3.2.jar
  [1.20.0-3.3]=v1.20.0/rumbledb-1.20.0-for-spark-3.3.jar
)

if [[ -z "$rumble_url" && -n "$spark_version" ]]
then
  echo "Automatically deriving RumbleDB URL..."

  rumble_filename=${RUMBLE_FILENAMES[$rumble_version-$spark_major.$spark_minor]}
  rumble_url="https://github.com/RumbleDB/rumble/releases/download/${rumble_filename}"
fi

#
# Assemble Docker tag.
#

if [[ -z "$docker_tag" && -n "$spark_version" && -n "$rumble_version" ]]
then
  echo "Automatically deriving Docker tag..."

  docker_tag="rumbledb/rumble:v$rumble_version-spark$spark_major"
fi


#
# Print arguments and build image.
#

if [[ -z "$spark_url" ]]
then
  echo "Could not determine Spark URL." 2>&1
  exit 1
fi

if [[ -z "$rumble_url" ]]
then
  echo "Could not determine Rumble URL." 2>&1
  exit 1
fi

if [[ -z "$docker_tag" ]]
then
  echo "Could not determine Docker tag." 2>&1
  exit 1
fi

echo "Spark URL: $spark_url"
echo "Rumble URL: $rumble_url"
echo "Docker tag: $docker_tag"

# Run build command
docker build "$ROOT_DIR"/docker -t ${docker_tag} \
    --build-arg SPARK_URL=${spark_url} \
    --build-arg RUMBLEDB_URL=${rumble_url}
