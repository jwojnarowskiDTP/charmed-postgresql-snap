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

#rizone setup database
while true; do
    # check leader statuspg_is_in_recovery()
    result=$(execute_query "SELECT pg_is_in_recovery();")
    # Sprawdź wynik
    if [ "$result" == "f" ]; then
        # create database and user
        execute_query "CREATE ROLE rizone WITH LOGIN PASSWORD 'rizone';"
        execute_query "CREATE DATABASE rizone OWNER rizone;"
        break
    else
        echo "Waiting to postgresql Leader..."
        sleep 10
    fi
done
