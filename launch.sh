#!/bin/bash

PROJECT_HOME="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SMAKE_HOME="$PROJECT_HOME/smake"

docker run --rm -it -m=4g -v$SMAKE_HOME:/smake directed-benchmark-final
