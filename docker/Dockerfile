#syntax=docker/dockerfile:1.2

#----------------------------------------------------------------
# Build Stage 1: Base 'generic' ghc + stack image
#----------------------------------------------------------------

FROM alpine:3.15.3 AS bld-stage1

# Note that the version here *MUST* match the GHC version of the
# Stackage LTS that we're using. The build will fail, badly, if
# that is not the case.
ARG GHC_VERSION="9.0.2"
# It is tempting to change this to use *_VERSION variables and interpolate those
# into the *_URL variables, but using URLs is much robust to upstream changes.
ARG GHCUP_URL="https://downloads.haskell.org/ghcup/0.1.17.6/x86_64-linux-ghcup-0.1.17.6"
ARG STACK_URL=https://github.com/commercialhaskell/stack/releases/download/v2.7.5/stack-2.7.5-linux-x86_64-bin

# Copy config and tools
COPY --chown=0:0 docker/fs-build-1/ /

# Base development tools for stack/ghc to use.
RUN apk update \
      && apk add \
           gcc g++ bash git make xz tar binutils-gold \
           perl curl file automake autoconf dpkg \
           fakeroot findutils shadow

# Install development libraries which are very typically required for Haskell
# projects.
RUN apk add \
      gmp-dev ncurses-dev \
      libffi libffi-dev \
      openssl-dev openssl-libs-static \
      xz xz-dev ncurses-static \
      pcre pcre-dev pcre2 pcre2-dev \
      bzip2 bzip2-dev bzip2-static \
      curl libcurl curl-static \
      zlib zlib-dev zlib-static

# Install ghcup
ENV GHCUP_INSTALL_BASE_PREFIX=/usr/local
ARG GHCUP_BIN_DIR=${GHCUP_INSTALL_BASE_PREFIX}/.ghcup/bin
RUN fetch-executable "$GHCUP_URL" "${GHCUP_BIN_DIR}/ghcup"

# Set up paths
ENV PATH="${GHCUP_BIN_DIR}:$PATH"

# Install the compiler which stack will use
RUN ghcup install ghc "$GHC_VERSION" \
        && ghcup set ghc "$GHC_VERSION"

# Install stack
ARG STACK=/usr/local/bin/stack
RUN fetch-executable "${STACK_URL}" "${STACK}"

#----------------------------------------------------------------
# Build Stage 2: Install project-specific C libraries
#----------------------------------------------------------------

FROM bld-stage1 AS bld-stage2

# Project C library dependencies
RUN apk add \
     # 'libpq' library
     postgresql-dev \
     # 'ldap' library
     openldap-dev \
     # 'hcrypto', etc.
     heimdal-dev \
     # 'gdbm' library
     gdbm-dev \
     # 'sqlite3' library
     sqlite-static \
     # 'sasl2' library
     cyrus-sasl-static \
     # 'gss' library
     libgss-dev \
     # 'com_err' library
     e2fsprogs-static

#----------------------------------------------------------------
# Build Stage 3: Build the project.
#----------------------------------------------------------------

FROM bld-stage2 AS bld-stage3

ARG STACK_ROOT=/cache/stack-root
ARG STACK_WORK=.stack-work-docker
RUN --mount=type=bind,source=server,target=/src,rw \
    --mount=type=cache,target=/cache \
    --mount=type=cache,target=/src/.stack-work-docker \
    cd src && ./build-static.sh

#----------------------------------------------------------------
# Server Stage 1: Base container for the server.
#----------------------------------------------------------------

# We use a different base image because we actually
# need a proper database inside the container for it
# to form a coherent 'logical' service.
FROM phusion/baseimage:focal-1.2.0 as srv-stage1

# Copy the file system contents
COPY --chown=0:0 docker/fs-server-1/ /

# Ask for non-interactive package installation
ARG DEBIAN_FRONTEND=noninteractive

# Update with security updates; it is important
# that we always do this -- otherwise package
# installation may fail.
RUN apt-get update && apt-get dist-upgrade

# Install everything we need into the base image
RUN apt-get install postgresql-12

# Remove APT files; we should not be installing anything
# in later stages.
RUN apt-get clean -y && \
    rm -rf \
        /var/lib/apt/lists/* \
        /tmp/* \
        /var/tmp/* \
        /var/log/dpkg.log \
        /var/log/alternatives.log \
        /var/log/apt

#----------------------------------------------------------------
# Server Stage 2: Set up the server
#----------------------------------------------------------------

FROM srv-stage1

# Copy the binary in
COPY --from=bld-stage3 /artifacts/tempgres-server /usr/local/bin

# Configuration
ENV HTTP_PORT 15431
ENV TEMPGRES_PUBLISHED_ADDRESS_PORT 15432
ENV TEMPGRES_PUBLISHED_ADDRESS_HOST localhost
ENV TEMPGRES_ADMIN_USER tempgres-admin
ENV TEMPGRES_ADMIN_PASS tempgres-apass
ENV TEMPGRES_CLIENT_USER tempgres-client
ENV TEMPGRES_CLIENT_PASS tempgres-cpass

# Exposed ports; we'll need to expose the embedded PostgreSQL instance too.
EXPOSE ${HTTP_PORT} ${TEMPGRES_PUBLISHED_ADDRESS_PORT}

# Copy all the file system bits; these contain the service files
# which initialize the database, set up roles, etc.
COPY --chown=0:0 docker/fs-server-2/ /

# Create tempgres user
RUN useradd --system tempgres

# Fix up permissions
RUN chmod a+rX /etc
RUN chmod -R a+rX /etc/runit/runsvdir/default/tempgres
