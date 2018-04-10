#!/bin/bash -e

export DEBIAN_FRONTEND=noninteractive

# Upgrade packages
apt-get update && apt-get upgrade -y -o Dpkg::Options::="--force-confold"

# Install basic packages
apt-get install -y \
  openjdk-8-jre-headless \
  postgresql-9.5
