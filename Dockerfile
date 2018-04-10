#
# See below for configuration (the "Configuration" comment)
#
FROM phusion/baseimage:0.10.1
MAINTAINER ba@cwconsult.dk

# Install everything we need into the base image
COPY docker/scripts/install.sh /docker/scripts/install.sh
RUN /docker/scripts/install.sh

# Warning avoidance
ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64

# Add the server
COPY target/pack /srv/pack

# Configuration:
#
#   HTTP_PORT is the port where the REST service will be exposed
#   PUBLISHED_ADDRESS_PORT is the port where the PostgreSQL instance will be exposed
#   PUBLISHED_ADDRESS_HOST is the host name of the PostgreSQL instance that will be exposed
#   PG_ADMIN_* are the user name/password to use for administrator account
#   PG_CLIENT_* are the user name/password to use for client (unprivileged) account
#
ENV HTTP_PORT 15431
ENV PUBLISHED_ADDRESS_PORT 15432
ENV PUBLISHED_ADDRESS_HOST localhost
ENV PG_ADMIN_USER tempgres-admin
ENV PG_ADMIN_PASS tempgres-apass
ENV PG_CLIENT_USER tempgres-client
ENV PG_CLIENT_PASS tempgres-cpass

# Exposed ports; we'll need to expose the embedded PostgreSQL instance too.
EXPOSE ${HTTP_PORT} ${PUBLISHED_ADDRESS_PORT}

# Copy all the file system bits we need when starting the container
COPY docker/service /etc/service
RUN chown 0:0 -R /etc/service && \
    chmod a+rX -R /etc/service

# Remove APT files
RUN apt-get clean -y && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
