#!/bin/sh

# Initialize a new PostgreSQL instance for every startup, just in case
# there were a few databases left behind from last run.
rm -rf /var/lib/postgresql/9.3/main/*
su postgres /init-db.sh

# Start PostgreSQL.
/etc/init.d/postgresql start

# Create the necessary roles
su postgres /create-roles.sh

# Start the server. This process does not daemonize.
/srv/pack/bin/tempgres-server
