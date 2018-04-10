#!/bin/bash

die() {
    echo "Failed to $*"
    exit 1
}

sbt clean pack \
  || die "build"

sudo docker build -t tempgres . \
  || die "build the docker image"

sudo docker run --name tempgres -p 15431:8080 -p 15432:5432 -i tempgres
