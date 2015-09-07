#!/bin/bash

die() {
    echo "Failed to $*"
    exit 1
}

sbt clean pack \
  || die "build"

sudo docker build -t tempgres . \
  || die "build the docker image"

sudo docker run --name tempgres -p 8080:8080 -p 5432:5432 -i tempgres
