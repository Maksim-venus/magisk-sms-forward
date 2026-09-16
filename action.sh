#!/system/bin/sh
MODDIR=${0%/*}
# Magisk Action: start local config UI and open browser
sh "$MODDIR/webui.sh" start
sleep 1
am start -a android.intent.action.VIEW -d "http://127.0.0.1:18080/" >/dev/null 2>&1 \
  || am start -a android.intent.action.VIEW -d "http://localhost:18080/" >/dev/null 2>&1 \
  || true
echo "SMS Forward WebUI: http://127.0.0.1:18080/"
