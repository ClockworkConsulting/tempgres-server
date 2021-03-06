# Tempgres: Temporary PostgreSQL databases on demand

`tempgres` is a REST service for conveniently creating temporary
PostgreSQL databases. It is intended for use from tests.

## Why?

This is mostly aimed at integration-type tests you usually want to use a) a real
database, and b) want to start with a fresh database for every test case. Using
this REST service eliminates the setup (users, configuration, database server,
etc.) which would be necessary for using temporary databases for tests locally
on a development machine -- all you need is a single URL.

If you have a group of developers, you'll probably want to run a single
`tempgres` instance in your development LAN so that everybody can share it
and can use the same URL. The URL could also be baked into the default
test configuration so that developers don't have to do any setup to get
tests up and running.

# Usage

## Java/Scala

An easy-to-use client library for Java/Scala is provided; see
the [tempgres-client](https://github.com/ClockworkConsulting/tempgres-client/blob/master/README.md) for documentation.

## REST

Once the service is set up and running (see below), you can do a HTTP
POST to it to create a temporary database. For example,

```
$ curl -d '' http://localhost:8080
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

We've published the docker image on DockerHub, so if you're OK with
using the default ports (15431 and 15432), then all you have to do is
run

```
$ docker run \
  --name=tempgres \
  -p 15431:8080 \
  -p 15432:5432 \
  cwconsult/tempgres:v1.1
```

to get started. After that's up and running, you should be be able to
POST to port 15431 on `localhost` and that should give you the
database name, host name, credentials, etc. for a temporary database.

**If you want to use different ports** you'll need to use change the
commands above accordingly, and you'll also need to set the
`HTTP_PORT` and `PUBLISHED_ADDRESS_HOST` environment variables via the
`-e` option to `docker run`; see the Docker documentation for more
information.

**If you want to use non-default user name/password combinations** you
can set the `PG_ADMIN_USER`, `PG_ADMIN_PASS`, `PG_CLIENT_USER` and
`PG_CLIENT_PASS` environment variables.

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
