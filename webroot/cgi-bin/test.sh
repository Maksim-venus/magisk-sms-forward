#!/system/bin/sh
echo "Content-Type: text/html; charset=utf-8"
echo ""
MODDIR=/data/adb/modules/smsforward
out=$(sh "$MODDIR/smsfwd.sh" --test 2>&1)
esc=$(printf '%s' "$out" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g')
echo "<!DOCTYPE html><html><head><meta charset=utf-8><meta name=viewport content=\"width=device-width,initial-scale=1\">
<style>body{font-family:sans-serif;background:#0b1220;color:#e8eefc;padding:24px}a{color:#7dd3fc}pre{white-space:pre-wrap;background:#111827;padding:12px;border-radius:8px}</style>
</head><body><h2>测试发送</h2><pre>$esc</pre><p><a href=/>返回配置</a></p></body></html>"
