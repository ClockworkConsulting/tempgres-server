#!/bin/sh

# Don't try to create roles if already created. This guards against
# restarts of the main server.
if [ -f $HOME/.roles-created ]; then
  exit 0
fi

echo "Creating roles..."
psql -o /dev/null <<EOF
CREATE ROLE "${TEMPGRES_ADMIN_USER}" ENCRYPTED PASSWORD '${TEMPGRES_ADMIN_PASS}' SUPERUSER CREATEDB CREATEROLE INHERIT LOGIN;
CREATE ROLE "${TEMPGRES_CLIENT_USER}" ENCRYPTED PASSWORD '${TEMPGRES_CLIENT_PASS}' INHERIT LOGIN;
EOF

touch $HOME/.roles-created
