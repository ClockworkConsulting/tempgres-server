#!/bin/bash -e

# Make sure we have an up-to-date base distribution
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get dist-upgrade -y
