#!/bin/bash

# For security measures, daemons should not be run as sudo. Execute patroni as the non-sudo user: snap_daemon.
export LOCPATH="${SNAP}"/usr/lib/locale

for dir in "${SNAP_DATA}/etc/patroni" "${SNAP_COMMON}/postgresql" "${SNAP_DATA}/postgresql" "${SNAP_COMMON}/raft"; do
    $SNAP/usr/bin/setpriv --clear-groups --reuid snap_daemon --regid snap_daemon -- mkdir -p "$dir"
done

if [ ! -e $SNAP_DATA/etc/patroni/patroni.yaml ]; then
  $SNAP/usr/bin/setpriv --clear-groups --reuid snap_daemon --regid snap_daemon -- cp $SNAP/config/patroni.yaml $SNAP_DATA/etc/patroni
fi

$SNAP/usr/bin/setpriv --clear-groups --reuid snap_daemon \
  --regid snap_daemon -- $SNAP/usr/bin/patroni $SNAP_DATA/etc/patroni/patroni.yaml "$@"
