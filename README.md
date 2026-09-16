# SMS Forward (Magisk)

Android 9+ Magisk module: forward **new** SMS to **Bark** and/or **SMTP**. Includes a **WebUI** for configuration.

## Install

1. Magisk → Modules → Install from storage → `smsforward-v1.2.0.zip`
2. Reboot

## Configure (WebUI)

1. Magisk → Modules → **SMS Forward** → tap **Action**
2. Browser opens `http://127.0.0.1:18080/`
3. Fill card name / Bark / SMTP → **保存**
4. Use **发送测试**

If the browser does not open, visit `http://127.0.0.1:18080/` manually on the phone.

## Config file

Still available at `/data/adb/modules/smsforward/config` (placeholders in examples only):

```sh
DEVICE_NAME=Card1
SIM_NUMBER=+1XXXXXXXXXX
BARK_KEY=YOUR_BARK_KEY
```

## Test / log

```sh
su -c 'sh /data/adb/modules/smsforward/smsfwd.sh --test'
```

Log: `/data/adb/modules/smsforward/state/smsfwd.log`
