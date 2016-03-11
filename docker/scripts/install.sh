#!/bin/bash -e

export DEBIAN_FRONTEND=noninteractive

# Make sure we have an up-to-date base distribution
apt-get update
apt-get dist-upgrade -y

# Add PostgreSQL APT repository
apt-get install -y wget ca-certificates
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -
echo "deb http://apt.postgresql.org/pub/repos/apt/ trusty-pgdg main" > /etc/apt/sources.list.d/pgdg.list

# Update package list
apt-get update

# Install basic packages
apt-get install -y \
  openjdk-7-jre-headless \
  postgresql-9.5

# Remove packages not needed at runtime
apt-get purge -y wget
apt-get autoremove -y
apt-get clean -y
