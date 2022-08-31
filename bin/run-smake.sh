#!/bin/bash

PROJECT_HOME="$(cd "$(dirname "${BASH_SOURCE[0]}")" && cd ../ && pwd)"
SMAKE_HOME="$PROJECT_HOME/smake"
BIN_DIR="$PROJECT_HOME/bin"

mkdir -p $PROJECT_HOME/rundirs/
CONTAINER=$(docker run --rm -id -v $SMAKE_HOME:/smake directed-benchmark /bin/bash)
docker cp $BIN_DIR/extract.sh $CONTAINER:/extract.sh
docker exec $CONTAINER /extract.sh $1
docker cp $CONTAINER:/RUNDIR-$1 $PROJECT_HOME/rundirs/
docker stop $CONTAINER
