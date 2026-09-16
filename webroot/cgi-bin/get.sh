#!/system/bin/sh
echo "Content-Type: application/json; charset=utf-8"
echo ""
MODDIR=/data/adb/modules/smsforward
CONFIG="$MODDIR/config"
# shell defaults
DEVICE_NAME=Card1; SIM_NUMBER=; POLL_INTERVAL=5
BARK_KEY=; BARK_SERVER=https://api.day.app
BARK_ICON=https://upload.wikimedia.org/wikipedia/commons/8/85/IMessage_icon.png
BARK_SOUND=glass
SMTP_HOST=; SMTP_PORT=587; SMTP_ENCRYPTION=starttls
SMTP_USER=; SMTP_PASS=; MAIL_FROM=; MAIL_TO=
TELEGRAM_BOT_TOKEN=; TELEGRAM_CHAT_ID=; WEBHOOK_URL=
[ -f "$CONFIG" ] && . "$CONFIG"

jesc() { printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g; s/	/\\t/g' | awk 'BEGIN{ORS=""} {gsub(/\r/,""); printf "%s%s", (NR>1?"\\n":""), $0}'; }

printf '{'
printf '"DEVICE_NAME":"%s",' "$(jesc "$DEVICE_NAME")"
printf '"SIM_NUMBER":"%s",' "$(jesc "$SIM_NUMBER")"
printf '"POLL_INTERVAL":"%s",' "$(jesc "$POLL_INTERVAL")"
printf '"BARK_KEY":"%s",' "$(jesc "$BARK_KEY")"
printf '"BARK_SERVER":"%s",' "$(jesc "$BARK_SERVER")"
printf '"BARK_ICON":"%s",' "$(jesc "$BARK_ICON")"
printf '"BARK_SOUND":"%s",' "$(jesc "$BARK_SOUND")"
printf '"SMTP_HOST":"%s",' "$(jesc "$SMTP_HOST")"
printf '"SMTP_PORT":"%s",' "$(jesc "$SMTP_PORT")"
printf '"SMTP_ENCRYPTION":"%s",' "$(jesc "$SMTP_ENCRYPTION")"
printf '"SMTP_USER":"%s",' "$(jesc "$SMTP_USER")"
printf '"SMTP_PASS":"%s",' "$(jesc "$SMTP_PASS")"
printf '"MAIL_FROM":"%s",' "$(jesc "$MAIL_FROM")"
printf '"MAIL_TO":"%s",' "$(jesc "$MAIL_TO")"
printf '"TELEGRAM_BOT_TOKEN":"%s",' "$(jesc "$TELEGRAM_BOT_TOKEN")"
printf '"TELEGRAM_CHAT_ID":"%s",' "$(jesc "$TELEGRAM_CHAT_ID")"
printf '"WEBHOOK_URL":"%s"' "$(jesc "$WEBHOOK_URL")"
printf '}\n'
