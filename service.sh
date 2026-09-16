#!/system/bin/sh
MODDIR=${0%/*}
(
  sleep 25
  while [ ! -f "$MODDIR/disable" ]; do
    sh "$MODDIR/smsfwd.sh" --daemon
    sleep 10
  done
) &
