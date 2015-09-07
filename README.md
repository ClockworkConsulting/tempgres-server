# Intro

`tempgres` is a REST service which for conveniently creating temporary
PostgreSQL databases. It is intended for use from tests.

# Usage

## Java/Scala

An easy-to-use client library for Java/Scala is provided; see
the [tempgres-client](https://github.com/ClockworkConsulting/tempgres-client/blob/master/README.md) for documentation.

## REST

Once the service is set up and running (see below), you can do a HTTP
POST to it to create a temporary database. For example,

```
$ curl -d '' http://localhost:8900
tempgres-client
tempgres-cpass
localhost
5432
temp_c23ff99a_ff56_4810_8692_7f779564b073
```

The response indicates that the temporary database `temp_c23ff...` has
been created on the database server `localhost` (port 5432) and made
available to the user `tempgres-client` using the password
`tempgres-cpass`.

The database will automatically be destroyed after a configurable
duration (see the `application.conf` file), though any temporary databases
that have not been destroyed when the service is stopped will stay around.
If you're using the Docker container, any lingering databases will be destroyed
on startup. All temporary databases will be named `temp_...`.

# Installation

The recommended installation option is to use a Docker container (see below).

## Prerequisites

To build the basic service you'll need [sbt](http://www.scala-sbt.org/) and to run it you'll
just need a JRE.

If you also want to run the service in Docker, you'll also need [Docker](https://www.docker.com/).

## Using Docker

A basic recipe for building is provided in the shell script
[try-docker.sh](https://github.com/ClockworkConsulting/tempgres-server/blob/master/try-docker.sh).

If you just need to do one-time setup, you can also run the steps in there manually:

```
$ sbt pack
...
$ docker build -t tempgres .
...
$ docker run --name tempgres -p 8080:8080 -p 5432:5432 -i tempgres
...
```

This sets up a Docker container which runs the REST service on port 8080
and runs its embedded PostgreSQL instance on port 5432.

If all those commands succeeded, you should have a running `tempgres` container
and you should be able to run the above `curl` command and connect (e.g. via
`psql`) to the temporary database.

**If you want to use different ports** you'll need to use change the commands
above accordingly, and you'll also need to modify the `HTTP_PORT`
and `PUBLISHED_ADDRESS_HOST` environment variables in the Dockerfile.

**If you want to use non-default user name/password combinations** you
can modify the `PG_ADMIN_USER`, `PG_ADMIN_PASS`, `PG_CLIENT_USER`
and `PG_CLIENT_PASS` variables.

## Manual Setup

You'll need to tweak the `application.conf` file and set up databases
and users appropriately (see comments in the file). See also the
scripts in `docker/fs` for some further hints if necessary.

To run directly, just do

```
$ sbt run
```

You can also package the application up into a standalone bundle in `target/pack`
by running the command

```
$ sbt pack
```

Note that `tempgres` uses [TypeSafe Config](https://github.com/typesafehub/config), so
you can override the baked-in configuration file at startup by setting the `config.file`
Java system property.


# Security

You should definitely **NOT** run this on any network facing the public
Internet since no attempt has been made to prevent DoS attacks and the
like. The `tempgres` REST service is only meant for development LANs
which are firewalled off.

# Copyright and License

This code is provided under the [Affero General Public License 3.0](https://github.com/ClockworkConsulting/tempgres-server/blob/master/LICENSE)
