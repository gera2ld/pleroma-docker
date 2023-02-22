#!/bin/sh

set -e

echo "-- Waiting for database..."
while ! pg_isready -U ${DB_USER:-pleroma} -d postgres://${DB_HOST:-db}:${DB_PORT:-5432}/${DB_NAME:-pleroma} -t 1; do
    sleep 1s
done

echo "-- Running migrations..."
su-exec pleroma mix ecto.migrate

echo "-- Starting server..."
su-exec pleroma mix phx.server
