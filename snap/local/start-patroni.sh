#!/bin/bash

# For security measures, daemons should not be run as sudo. Execute patroni as the non-sudo user: snap_daemon.
export LOCPATH="${SNAP}"/usr/lib/locale
export USER_ID="584788" # hack - we need to make sure we can run setpriv. Maybe we can create some user instead in context of snap only ?
$SNAP/usr/bin/setpriv --clear-groups --reuid $USER_ID --regid $USER_ID -- mkdir -p $SNAP_DATA/etc/patroni
$SNAP/usr/bin/setpriv --clear-groups --reuid $USER_ID --regid $USER_ID -- mkdir -p $SNAP_COMMON/postgresql
$SNAP/usr/bin/setpriv --clear-groups --reuid $USER_ID --regid $USER_ID -- mkdir -p $SNAP_DATA/postgresql
$SNAP/usr/bin/setpriv --clear-groups --reuid $USER_ID --regid $USER_ID -- mkdir -p $SNAP_COMMON/raft

if [ ! -e $SNAP_DATA/etc/patroni/patroni.yaml ]; then
  $SNAP/usr/bin/setpriv --clear-groups --reuid $USER_ID --regid $USER_ID -- cp $SNAP/config/patroni.yaml $SNAP_DATA/etc/patroni
fi

$SNAP/usr/bin/setpriv --clear-groups --reuid $USER_ID \
  --regid $USER_ID -- $SNAP/usr/bin/patroni $SNAP_DATA/etc/patroni/patroni.yaml "$@"
