#!/bin/bash

# For security measures, daemons should not be run as sudo. Execute patroni as the non-sudo user: snap_daemon.
export LOCPATH="${SNAP}"/usr/lib/locale

execute_query() {
    local query=$1
    /snap/bin/charmed-postgresql.psql -h localhost -p 5432 -U postgres -c "$query" -t -A
}


$SNAP/usr/bin/setpriv --clear-groups --reuid snap_daemon --regid snap_daemon -- mkdir -p $SNAP_DATA/etc/patroni
$SNAP/usr/bin/setpriv --clear-groups --reuid snap_daemon --regid snap_daemon -- mkdir -p $SNAP_COMMON/postgresql
$SNAP/usr/bin/setpriv --clear-groups --reuid snap_daemon --regid snap_daemon -- mkdir -p $SNAP_DATA/postgresql
$SNAP/usr/bin/setpriv --clear-groups --reuid snap_daemon --regid snap_daemon -- mkdir -p $SNAP_COMMON/raft

if [ ! -e $SNAP_DATA/etc/patroni/patroni.yaml ]; then
  $SNAP/usr/bin/setpriv --clear-groups --reuid snap_daemon --regid snap_daemon -- cp $SNAP/config/patroni.yaml $SNAP_DATA/etc/patroni
fi

$SNAP/usr/bin/setpriv --clear-groups --reuid snap_daemon \
  --regid snap_daemon -- $SNAP/usr/bin/patroni $SNAP_DATA/etc/patroni/patroni.yaml "$@"

# rizone setup database
max_attempts=30
attempt=0
while [ $attempt -lt $max_attempts ]; do
    # check leader status
    result=$(execute_query "SELECT pg_is_in_recovery();")
    if [ "$result" == "f" ]; then
        # Check if user and database already exist
        user_exists=$(execute_query "SELECT 1 FROM pg_roles WHERE rolname='rizone';")
        db_exists=$(execute_query "SELECT 1 FROM pg_database WHERE datname='rizone';")

        if [ "$user_exists" != "1" ]; then
            execute_query "CREATE ROLE rizone WITH LOGIN PASSWORD 'rizone';" || { echo "Failed to create role rizone"; exit 1; }
        fi

        if [ "$db_exists" != "1" ]; then
            execute_query "CREATE DATABASE rizone OWNER rizone;" || { echo "Failed to create database rizone"; exit 1; }
        fi
        echo "[RIZONE] Database and user setup completed successfully."
        break
    else
        echo "[RIZONE] Waiting to postgresql Leader..."
        sleep 10
        attempt=$((attempt + 1))
    fi
done &

# if [ $attempt -eq $max_attempts ]; then
#     echo "Timed out waiting for postgresql Leader."
#     exit 1
# fi
