#!/system/bin/sh
# Magisk SMS Forward — Bark + SMTP + optional Telegram/Webhook
# Android 9+

MODDIR="${MODDIR:-$(cd "$(dirname "$0")" && pwd)}"
CONFIG="${MODDIR}/config"
STATEDIR="${MODDIR}/state"
LAST_ID_FILE="${STATEDIR}/last_id"
LOG_FILE="${STATEDIR}/smsfwd.log"
LOCK_FILE="${STATEDIR}/smsfwd.lock"

mkdir -p "$STATEDIR"

log() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') $*" >> "$LOG_FILE"
  if [ -f "$LOG_FILE" ]; then
    lines=$(wc -l < "$LOG_FILE" 2>/dev/null || echo 0)
    if [ "$lines" -gt 500 ]; then
      tail -n 250 "$LOG_FILE" > "${LOG_FILE}.tmp" 2>/dev/null && mv "${LOG_FILE}.tmp" "$LOG_FILE"
    fi
  fi
}

load_config() {
  DEVICE_NAME="Card1"
  SIM_NUMBER=
  POLL_INTERVAL=5
  BARK_KEY=
  BARK_SERVER=https://api.day.app
  BARK_ICON=https://upload.wikimedia.org/wikipedia/commons/8/85/IMessage_icon.png
  BARK_SOUND=glass
  SMTP_HOST=
  SMTP_PORT=587
  SMTP_ENCRYPTION=starttls
  SMTP_USER=
  SMTP_PASS=
  MAIL_FROM=
  MAIL_TO=
  TELEGRAM_BOT_TOKEN=
  TELEGRAM_CHAT_ID=
  WEBHOOK_URL=
  # shellcheck disable=SC1090
  [ -f "$CONFIG" ] && . "$CONFIG"
  [ -n "$POLL_INTERVAL" ] || POLL_INTERVAL=5
  [ -n "$DEVICE_NAME" ] || DEVICE_NAME="Card1"
  [ -n "$BARK_SERVER" ] || BARK_SERVER=https://api.day.app
  [ -n "$SMTP_PORT" ] || SMTP_PORT=587
  [ -n "$MAIL_FROM" ] && [ -n "$SMTP_USER" ] || true
  [ -z "$MAIL_FROM" ] && [ -n "$SMTP_USER" ] && MAIL_FROM="$SMTP_USER"
}

find_curl() {
  for c in \
    "$MODDIR/bin/curl" \
    /data/adb/magisk/busybox \
    curl
  do
    if [ -x "$c" ] && [ "$(basename "$c")" = curl ]; then
      CURL="$c"; return 0
    fi
    if [ -x "$c" ] && [ "$(basename "$c")" != curl ]; then
      # busybox may not have curl
      :
    fi
  done
  if command -v curl >/dev/null 2>&1; then
    CURL=$(command -v curl); return 0
  fi
  # Magisk busybox as wget fallback for HTTP only
  CURL=
  return 1
}

find_wget() {
  if [ -x /data/adb/magisk/busybox ]; then
    WGET="/data/adb/magisk/busybox wget"
    return 0
  fi
  if command -v wget >/dev/null 2>&1; then
    WGET="wget"
    return 0
  fi
  WGET=
  return 1
}

json_escape() {
  printf '%s' "$1" | sed \
    -e 's/\\/\\\\/g' \
    -e 's/"/\\"/g' \
    -e 's/	/\\t/g' \
    -e ':a;N;$!ba;s/\n/\\n/g' \
    -e 's/\r//g'
}

http_post_json() {
  url="$1"
  body="$2"
  printf '%s' "$body" > "${STATEDIR}/post.json"
  if find_curl; then
    "$CURL" -sS -X POST -H 'Content-Type: application/json' --data-binary @"${STATEDIR}/post.json" "$url" >/dev/null 2>&1
    return $?
  fi
  if find_wget; then
    # shellcheck disable=SC2086
    $WGET -q -O /dev/null --header='Content-Type: application/json' --post-file="${STATEDIR}/post.json" "$url" 2>/dev/null
    return $?
  fi
  log "no curl/wget for HTTP"
  return 1
}

bark_url() {
  if echo "$BARK_KEY" | grep -q '^https://\|^http://'; then
    echo "$BARK_KEY"
  else
    echo "${BARK_SERVER%/}/$BARK_KEY"
  fi
}

send_bark() {
  from="$1"
  body="$2"
  [ -n "$BARK_KEY" ] || return 0
  title_j=$(json_escape "${DEVICE_NAME} · ${from}")
  body_text="${body}"
  if [ -n "$SIM_NUMBER" ]; then
    body_text="${body}\n\nSIM 手机号：${SIM_NUMBER}"
  fi
  body_j=$(json_escape "$body_text")
  group_j=$(json_escape "${DEVICE_NAME} 信息")
  icon_j=$(json_escape "$BARK_ICON")
  sound_j=$(json_escape "$BARK_SOUND")
  payload=$(printf '{"title":"%s","body":"%s","group":"%s","icon":"%s","sound":"%s"}' \
    "$title_j" "$body_j" "$group_j" "$icon_j" "$sound_j")
  url=$(bark_url)
  if http_post_json "$url" "$payload"; then
    log "bark ok from=$from"
    return 0
  fi
  log "bark FAIL from=$from"
  return 1
}

send_smtp() {
  from="$1"
  body="$2"
  [ -n "$SMTP_HOST" ] && [ -n "$SMTP_USER" ] && [ -n "$SMTP_PASS" ] && [ -n "$MAIL_TO" ] || return 0
  [ -n "$MAIL_FROM" ] || MAIL_FROM="$SMTP_USER"

  subject="[SMS Forward]${DEVICE_NAME}+${from}"
  mail_body="$body"
  if [ -n "$SIM_NUMBER" ]; then
    mail_body="${body}

SIM 手机号：${SIM_NUMBER}"
  fi

  # Build raw RFC822 message
  {
    printf 'From: %s\r\n' "$MAIL_FROM"
    printf 'To: %s\r\n' "$MAIL_TO"
    printf 'Subject: %s\r\n' "$subject"
    printf 'MIME-Version: 1.0\r\n'
    printf 'Content-Type: text/plain; charset=UTF-8\r\n'
    printf 'Content-Transfer-Encoding: 8bit\r\n'
    printf '\r\n'
    printf '%s\n' "$mail_body"
  } > "${STATEDIR}/mail.eml"

  if ! find_curl; then
    log "smtp FAIL: need curl for SMTP (place binary at $MODDIR/bin/curl)"
    return 1
  fi

  enc=$(echo "$SMTP_ENCRYPTION" | tr 'A-Z' 'a-z')
  case "$enc" in
    ssl|smtps)
      url="smtps://${SMTP_HOST}:${SMTP_PORT}"
      sslflag="--ssl"
      ;;
    none)
      url="smtp://${SMTP_HOST}:${SMTP_PORT}"
      sslflag=""
      ;;
    *)
      # starttls default (iCloud: smtp.mail.me.com:587)
      url="smtp://${SMTP_HOST}:${SMTP_PORT}"
      sslflag="--ssl-reqd"
      ;;
  esac

  # curl SMTP
  # shellcheck disable=SC2086
  if "$CURL" -sS --url "$url" $sslflag \
      --mail-from "$MAIL_FROM" \
      --mail-rcpt "$MAIL_TO" \
      --user "${SMTP_USER}:${SMTP_PASS}" \
      -T "${STATEDIR}/mail.eml" >/dev/null 2>&1; then
    log "smtp ok from=$from to=$MAIL_TO"
    return 0
  fi
  log "smtp FAIL from=$from host=$SMTP_HOST"
  return 1
}

send_telegram() {
  from="$1"
  body="$2"
  [ -n "$TELEGRAM_BOT_TOKEN" ] && [ -n "$TELEGRAM_CHAT_ID" ] || return 0
  text="📩 ${DEVICE_NAME}
From: $from
$body"
  if [ -n "$SIM_NUMBER" ]; then
    text="${text}

SIM: $SIM_NUMBER"
  fi
  from_j=$(json_escape "$DEVICE_NAME")
  # reuse full text escape
  text_j=$(json_escape "$text")
  payload=$(printf '{"chat_id":"%s","text":"%s"}' "$TELEGRAM_CHAT_ID" "$text_j")
  url="https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage"
  if http_post_json "$url" "$payload"; then
    log "telegram ok from=$from"
    return 0
  fi
  log "telegram FAIL from=$from"
  return 1
}

send_webhook() {
  from="$1"
  body="$2"
  [ -n "$WEBHOOK_URL" ] || return 0
  from_j=$(json_escape "$from")
  body_j=$(json_escape "$body")
  name_j=$(json_escape "$DEVICE_NAME")
  sim_j=$(json_escape "$SIM_NUMBER")
  payload=$(printf '{"device":"%s","from":"%s","body":"%s","sim":"%s"}' \
    "$name_j" "$from_j" "$body_j" "$sim_j")
  if http_post_json "$WEBHOOK_URL" "$payload"; then
    log "webhook ok from=$from"
    return 0
  fi
  log "webhook FAIL from=$from"
  return 1
}

has_destination() {
  [ -n "$BARK_KEY" ] && return 0
  [ -n "$SMTP_HOST" ] && [ -n "$MAIL_TO" ] && return 0
  [ -n "$TELEGRAM_BOT_TOKEN" ] && return 0
  [ -n "$WEBHOOK_URL" ] && return 0
  return 1
}

forward_one() {
  from="$1"
  body="$2"
  date_epoch="$3"
  ok=0
  send_bark "$from" "$body" && ok=1
  send_smtp "$from" "$body" && ok=1
  send_telegram "$from" "$body" && ok=1
  send_webhook "$from" "$body" && ok=1
  [ "$ok" -eq 1 ]
}

query_sms() {
  content query --uri content://sms/inbox --projection _id:address:body:date 2>/dev/null \
    || content query --uri content://sms --where "type=1" --projection _id:address:body:date 2>/dev/null
}

parse_and_process() {
  last_id=0
  [ -f "$LAST_ID_FILE" ] && last_id=$(cat "$LAST_ID_FILE" 2>/dev/null || echo 0)
  [ -n "$last_id" ] || last_id=0
  max_seen=$last_id
  bootstrap=0
  [ ! -f "$LAST_ID_FILE" ] && bootstrap=1

  while IFS= read -r line || [ -n "$line" ]; do
    echo "$line" | grep -q '_id=' || continue
    id=$(echo "$line" | sed -n 's/.*_id=\([0-9][0-9]*\).*/\1/p' | head -1)
    [ -n "$id" ] || continue
    [ "$id" -gt "$max_seen" ] && max_seen=$id
    [ "$bootstrap" -eq 1 ] && continue
    [ "$id" -le "$last_id" ] && continue
    addr=$(echo "$line" | sed -n 's/.*address=\([^,]*\).*/\1/p' | head -1)
    body=$(echo "$line" | sed -n 's/.*body=\(.*\), date=.*/\1/p' | head -1)
    [ -n "$body" ] || body=$(echo "$line" | sed -n 's/.*body=\(.*\)$/\1/p' | head -1)
    date_ms=$(echo "$line" | sed -n 's/.*date=\([0-9][0-9]*\).*/\1/p' | head -1)
    date_epoch=$date_ms
    if [ "${#date_ms}" -gt 10 ]; then
      date_epoch=$(echo "$date_ms" | sed 's/...$//')
    fi
    forward_one "$addr" "$body" "$date_epoch" || true
  done

  echo "$max_seen" > "$LAST_ID_FILE"
  [ "$bootstrap" -eq 1 ] && log "bootstrap last_id=$max_seen (skip existing)"
}

run_once() {
  load_config
  has_destination || { log "no destination — edit $CONFIG"; return 1; }
  dump=$(query_sms)
  printf '%s\n' "$dump" | parse_and_process
}

run_test() {
  load_config
  has_destination || { echo "ERROR: configure Bark/SMTP in $CONFIG"; return 1; }
  forward_one "8080" "Your remaining data is 10GB. (test $(date '+%F %T'))" "$(date +%s)"
  echo "Test sent for DEVICE_NAME=$DEVICE_NAME. Check Bark/email and $LOG_FILE"
}

run_daemon() {
  load_config
  if ! has_destination; then
    log "daemon: waiting for config"
    sleep 60
    return 0
  fi
  if mkdir "$LOCK_FILE" 2>/dev/null; then
    trap 'rmdir "$LOCK_FILE" 2>/dev/null' EXIT
  else
    return 0
  fi
  log "daemon start device=$DEVICE_NAME poll=${POLL_INTERVAL}s"
  while [ ! -f "$MODDIR/disable" ]; do
    load_config
    dump=$(query_sms)
    printf '%s\n' "$dump" | parse_and_process
    sleep "$POLL_INTERVAL"
  done
}

case "${1:---daemon}" in
  --daemon) run_daemon ;;
  --once) run_once ;;
  --test) run_test ;;
  *) echo "usage: $0 [--daemon|--once|--test]"; exit 1 ;;
esac
