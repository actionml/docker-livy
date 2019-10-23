#!/bin/bash
set -e

## Defaults
#
: ${SPARK_HOME:?must be set!}
: ${HADOOP_HOME:?must be set!}
: ${LIVY_HOME:?must be set!}
: ${MONGO_URI:?must be set!}
: ${ELASTICSEARCH_REST_HOST:?must be set!}

/livy/bin/livy-server