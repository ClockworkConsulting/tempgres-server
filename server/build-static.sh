#!/usr/bin/env bash
set -euo pipefail

# Libraries we must link in to have a fully static
# binary.
LIBS=(
    # Order is extremely important here; symbols
    # required by a library must be provided by
    # a library LATER in the list.
    pq
    pgcommon
    pgport
    ldap_r
    ssl
    crypto
    lber
    sasl2
    gssapi
    gss
    krb5
    hx509
    asn1
    hcrypto
    roken
    wind
    heimbase
    sqlite3
    com_err
    heimntlm
    crypto
    gdbm
)

# Build the command line linker options
OPTL_OPTS=()
for LIB in "${LIBS[@]}"; do
    OPTL_OPTS+=("-optl-l$LIB")
done

# Function to add the options we always
# need.
stack() {
    /usr/local/bin/stack --system-ghc --allow-different-user "$@"
}

# Build
stack test \
    --ghc-options \
    "${OPTL_OPTS[*]} -static \
    -optl-static \
    -optl-pthread \
    -fPIC" \
    tempgres-server

# Copy the build artifact to a well-known location.
mkdir /artifacts
cp `stack path --local-install-root`/bin/tempgres-server /artifacts
