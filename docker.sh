#!/bin/bash

set -o nounset

readonly IMAGE=vm2gol-v2-crystal:8

cmd_build() {
  docker build \
    --build-arg USER=$USER \
    --build-arg GROUP=$(id -gn) \
    -t $IMAGE .
}

cmd_run() {
  docker run --rm -it \
    -v "$(pwd):/home/${USER}/work" \
    $IMAGE "$@"
}

cmd="$1"; shift
case $cmd in
  build | b* )
    cmd_build "$@"
;; run | r* )
     cmd_run "$@"
;; * )
     echo "invalid command (${cmd})" >&2
     ;;
esac
