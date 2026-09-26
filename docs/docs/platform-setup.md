---
sidebar_position: 3
title: Platform Setup
---

# Platform Setup

Authentication runs in the external browser. When it finishes, the browser opens a URL with your app's custom scheme, and the OS hands that URL back to the app. You register the scheme in the app; the library does not add it to your Manifest or `Info.plist`.

Use the same scheme string on iOS (`CFBundleURLSchemes`) and Android (`<data android:scheme="...">`). They must match exactly.

## iOS

Add the scheme to `ios/Runner/Info.plist`:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLName</key>
        <string>com.yourcompany.yourapp</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>yourscheme</string>
        </array>
    </dict>
</array>
```

## Android

Add `CallbackActivity` from `flutter_web_auth_2` to `android/app/src/main/AndroidManifest.xml`:

```xml
<activity
    android:name="com.linusu.flutter_web_auth_2.CallbackActivity"
    android:exported="true"
    android:taskAffinity="">
    <intent-filter>
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.DEFAULT" />
        <category android:name="android.intent.category.BROWSABLE" />
        <!-- Minimum: scheme only -->
        <data android:scheme="yourscheme" />
        <!-- Optional (OAuth only): restrict host/path to the custom scheme URL the browser finally opens.
             MiAuth calls back to `yourscheme://` without host/path, so keep the scheme-only filter if you use MiAuth. -->
        <!-- <data android:scheme="yourscheme" android:host="oauth" android:path="/callback" /> -->
    </intent-filter>
</activity>
```

A complete configuration is in [`example/android/app/src/main/AndroidManifest.xml`](https://github.com/LibraryLibrarian/misskey_auth/blob/main/example/android/app/src/main/AndroidManifest.xml). Treat it as the reference for Android.

Notes:

- The `android:label` attribute on the `<intent-filter>` is optional.
- On Android 12 and later (API 31+), an Activity with an `intent-filter` must declare `android:exported="true"`.
- Apps that make network requests must declare `<uses-permission android:name="android.permission.INTERNET" />` directly under `<manifest>` in `android/app/src/main/AndroidManifest.xml`. A declaration in the `debug` or `profile` Manifest does not apply to release builds.
- If you restrict the intent-filter by host or path, match the custom scheme URL that the browser finally opens: `redirect_uri` itself, or the URL that your relay page forwards to. Do not restrict it if you also use MiAuth, which calls back to `yourscheme://`.

### When the Browser Tab Stays Open

The sample Manifest sets `android:taskAffinity=""` on both the exported `MainActivity` and `CallbackActivity`, as `flutter_web_auth_2` recommends.

With that setting, the browser tab may stay open after authentication when the default browser does not support Auth Tab (for example, Chrome earlier than 137). Authentication still succeeds, but the user has to close the tab. `flutter_web_auth_2` uses Auth Tab when the browser supports it and falls back to a Custom Tab otherwise. On the fallback path tested with Chrome 109, Chrome starts `CallbackActivity` in a new task, so it cannot close the tab left in the app's task.

- To close the tab on the fallback path too, remove `android:taskAffinity=""` from both `MainActivity` and `CallbackActivity`. Removing it from only one of them does not help. With Auth Tab, this change is not needed; on Android 13 with Chrome 154, the tab closed with either setting.
- `taskAffinity=""` is sometimes used as a partial mitigation against task hijacking (StrandHogg) on devices before Android 11 (API 30). Android's own recommendation for this vulnerability is `minSdkVersion` 30 or later. See [flutter_web_auth_2 issue #158](https://github.com/ThexXTURBOXx/flutter_web_auth_2/issues/158) for the upstream discussion.

### `PlatformException(CANCELED, User canceled login, ...)`

The library reports this as `UserCancelledException`. If it happens even though the user did not cancel, common causes are:

1. The callback did not reach the app. Check that `CallbackActivity` has a matching `<intent-filter>`.
2. A PWA or another app intercepted the link.
3. The `redirect_uri` did not exactly match a `<link rel="redirect_uri">` on the client_id page, so Misskey did not redirect back.
