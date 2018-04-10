#!/bin/sh
while ! psql -q -c "SELECT 1;" > /dev/null 2>&1 ; do
  echo "Waiting for PostgreSQL to start..."
  sleep 1
done
