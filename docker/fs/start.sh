#!/bin/sh

# Fix weird permissions
chmod 755 /etc
chmod 755 /*.sh

# Initialize a new PostgreSQL cluster for every startup, just in case
# there were a few databases left behind from last run.
/usr/bin/pg_dropcluster 9.5 main
/usr/bin/pg_createcluster 9.5 main

# Start PostgreSQL.
/etc/init.d/postgresql start

# Create the necessary roles
su postgres /create-roles.sh

# Start the server. This process does not daemonize.
/srv/pack/bin/tempgres-server
