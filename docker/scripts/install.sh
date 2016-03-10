#!/bin/bash -e

export DEBIAN_FRONTEND=noninteractive

# Add PostgreSQL APT repository
apt-get install -y wget ca-certificates
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -
echo "deb http://apt.postgresql.org/pub/repos/apt/ trusty-pgdg main" > /etc/apt/sources.list.d/pgdg.list

# Make sure we have an up-to-date base distribution
apt-get update
apt-get dist-upgrade -y

# Install basic packages
apt-get install -y \
  openjdk-7-jre-headless \
  postgresql-9.5

# Remove packages not needed at runtime
apt-get purge -y wget
apt-get autoremove -y
apt-get clean -y

# Make sure PostgreSQL will accept connections from anywhere
echo "host all  all    0.0.0.0/0  md5" >> /etc/postgresql/9.5/main/pg_hba.conf
echo "listen_addresses='*'"            >> /etc/postgresql/9.5/main/postgresql.conf
