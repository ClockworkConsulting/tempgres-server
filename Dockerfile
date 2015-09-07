#
# See below for configuration (the "Configuration" comment)
#
FROM ubuntu:trusty
MAINTAINER ba@cwconsult.dk

# Make /tmp writable by world
RUN chmod 777 /tmp

# Make sure base image is up-to-date
COPY docker/scripts/install-pre.sh /docker/scripts/install-pre.sh
RUN /docker/scripts/install-pre.sh

# Install everything we need into the base image
COPY docker/scripts/install-post.sh /docker/scripts/install-post.sh
RUN /docker/scripts/install-post.sh

# Warning avoidance
ENV JAVA_HOME /usr/lib/jvm/java-7-openjdk-amd64

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
ENV HTTP_PORT 8080
ENV PUBLISHED_ADDRESS_PORT 5432
ENV PUBLISHED_ADDRESS_HOST localhost
ENV PG_ADMIN_USER tempgres-admin
ENV PG_ADMIN_PASS tempgres-apass
ENV PG_CLIENT_USER tempgres-client
ENV PG_CLIENT_PASS tempgres-cpass

# Exposed ports; we'll need to expose the embedded PostgreSQL instance too.
EXPOSE ${HTTP_PORT} ${PUBLISHED_ADDRESS_PORT}

# Copy all the file system bits we need when starting the container
COPY docker/fs /

# Append configuration extras for PostgreSQL for performance
RUN cat /etc/postgresql.conf.tail >> /etc/postgresql/9.3/main/postgresql.conf

# Override default CMD set in ubuntu trusty Dockerfile
CMD ["/start.sh"]
