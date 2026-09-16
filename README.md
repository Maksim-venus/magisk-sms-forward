# SMS Forward (Magisk)

Android 9+ Magisk module: forward **new** SMS to **Bark** and/or **SMTP**. Custom card name supported.

## Install

1. Magisk → Modules → Install from storage → `smsforward-v1.1.0.zip`
2. Reboot
3. Edit `/data/adb/modules/smsforward/config`

## Config (placeholders)

```sh
DEVICE_NAME=Card1
SIM_NUMBER=+1XXXXXXXXXX

BARK_KEY=YOUR_BARK_KEY

SMTP_HOST=smtp.mail.me.com
SMTP_PORT=587
SMTP_ENCRYPTION=starttls
SMTP_USER=you@example.com
SMTP_PASS=YOUR_APP_PASSWORD
MAIL_FROM=you@example.com
MAIL_TO=receiver@example.com
```

### Bark

- Title: `{DEVICE_NAME} · {sender}`
- Body: SMS text + SIM line
- Group: `{DEVICE_NAME} 信息`

### Email

- Subject: `[SMS Forward]{DEVICE_NAME}+{sender}`
- Body: SMS text + SIM line

## Test

```sh
su -c 'sh /data/adb/modules/smsforward/smsfwd.sh --test'
```

Log: `/data/adb/modules/smsforward/state/smsfwd.log`
