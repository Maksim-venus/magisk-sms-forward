#!/system/bin/sh
MODDIR="${MODDIR:-$(cd "$(dirname "$0")" && pwd)}"
PORT=18080
PIDFILE="$MODDIR/state/webui.pid"
LOG="$MODDIR/state/webui.log"
WEBROOT="$MODDIR/webroot"
mkdir -p "$MODDIR/state"

BB=
[ -x /data/adb/magisk/busybox ] && BB=/data/adb/magisk/busybox

stop_ui() {
  if [ -f "$PIDFILE" ]; then
    kill "$(cat "$PIDFILE")" 2>/dev/null || true
    rm -f "$PIDFILE"
  fi
}

start_ui() {
  stop_ui
  chmod -R 755 "$WEBROOT/cgi-bin" 2>/dev/null || true

  if [ -n "$BB" ]; then
    # httpd.conf in webroot for relative cgi
    cat > "$WEBROOT/httpd.conf" <<CONF
A:*
I:index.html
*.sh:$BB
CONF
    # -c conf path relative to -h home in some builds; pass absolute when supported
    "$BB" httpd -p "0.0.0.0:$PORT" -h "$WEBROOT" -c httpd.conf >>"$LOG" 2>&1 &
    echo $! > "$PIDFILE"
    echo "$(date) httpd via magisk busybox pid=$(cat "$PIDFILE")" >>"$LOG"
  elif command -v httpd >/dev/null 2>&1; then
    httpd -p "$PORT" -h "$WEBROOT" >>"$LOG" 2>&1 &
    echo $! > "$PIDFILE"
  else
    echo "$(date) ERROR no busybox httpd" >>"$LOG"
    echo "ERROR: need Magisk busybox httpd"
    return 1
  fi

  (
    sleep 600
    stop_ui
  ) >/dev/null 2>&1 &
}

case "$1" in
  stop) stop_ui ;;
  *) start_ui ;;
esac
