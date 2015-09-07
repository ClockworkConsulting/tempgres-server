#!/bin/bash -e

# Install basic packages
export DEBIAN_FRONTEND=noninteractive
apt-get install -y openjdk-7-jre-headless
apt-get install -y postgresql

# Make sure PostgreSQL will accept connections from anywhere
echo "host all  all    0.0.0.0/0  md5" >> /etc/postgresql/9.3/main/pg_hba.conf
echo "listen_addresses='*'"            >> /etc/postgresql/9.3/main/postgresql.conf
