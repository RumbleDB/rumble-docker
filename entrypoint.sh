#!/bin/bash

/opt/spark/bin/spark-submit $SPARK_SUBMIT_OPTIONS /opt/spark/jars/spark-rumble-jar-with-dependencies.jar "$@"
