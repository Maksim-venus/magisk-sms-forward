#!/system/bin/sh
echo "Content-Type: text/html; charset=utf-8"
echo ""
MODDIR=/data/adb/modules/smsforward
logf="$MODDIR/state/smsfwd.log"
if [ -f "$logf" ]; then
  body=$(tail -n 80 "$logf" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g')
else
  body="(暂无日志)"
fi
echo "<!DOCTYPE html><html><head><meta charset=utf-8><meta name=viewport content=\"width=device-width,initial-scale=1\">
<style>body{font-family:sans-serif;background:#0b1220;color:#e8eefc;padding:24px}a{color:#7dd3fc}pre{white-space:pre-wrap;background:#111827;padding:12px;border-radius:8px;font-size:12px}</style>
</head><body><h2>日志</h2><pre>$body</pre><p><a href=/>返回配置</a></p></body></html>"
