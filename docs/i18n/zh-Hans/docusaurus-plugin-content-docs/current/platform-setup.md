---
sidebar_position: 3
title: 平台配置
---

# 平台配置

身份验证在外部浏览器中进行。完成后，浏览器会打开一个使用应用自定义 scheme 的 URL，操作系统再将该 URL 交给应用。scheme 由应用注册；库不会将其添加到 Manifest 或 `Info.plist` 中。

iOS（`CFBundleURLSchemes`）和 Android（`<data android:scheme="...">`）必须注册相同的 scheme 字符串，且必须完全匹配。

## iOS

在 `ios/Runner/Info.plist` 中添加 scheme：

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

将 `flutter_web_auth_2` 的 `CallbackActivity` 添加到 `android/app/src/main/AndroidManifest.xml`：

```xml
<activity
    android:name="com.linusu.flutter_web_auth_2.CallbackActivity"
    android:exported="true"
    android:taskAffinity="">
    <intent-filter>
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.DEFAULT" />
        <category android:name="android.intent.category.BROWSABLE" />
        <!-- 最小配置：仅指定 scheme -->
        <data android:scheme="yourscheme" />
        <!-- 可选（仅适用于 OAuth）：将 host/path 限制为浏览器最终打开的自定义 scheme URL。
             MiAuth 会回调到不带 host/path 的 `yourscheme://`，因此如果也使用 MiAuth，请保留仅指定 scheme 的过滤器。 -->
        <!-- <data android:scheme="yourscheme" android:host="oauth" android:path="/callback" /> -->
    </intent-filter>
</activity>
```

完整配置请参阅 [`example/android/app/src/main/AndroidManifest.xml`](https://github.com/LibraryLibrarian/misskey_auth/blob/main/example/android/app/src/main/AndroidManifest.xml)。Android 配置请以此文件为准。

注意事项：

- `<intent-filter>` 上的 `android:label` 属性是可选的。
- 在 Android 12 及更高版本（API 31+）中，带有 `intent-filter` 的 Activity 必须声明 `android:exported="true"`。
- 需要进行网络请求的应用必须在 `android/app/src/main/AndroidManifest.xml` 中 `<manifest>` 的直接子级处声明 `<uses-permission android:name="android.permission.INTERNET" />`。仅在 `debug` 或 `profile` Manifest 中声明不会应用于 release 构建。
- 如果通过 host 或 path 限制 intent-filter，请匹配浏览器最终打开的自定义 scheme URL：`redirect_uri` 本身，或中继页面转发到的 URL。如果也使用 MiAuth，请勿进行限制，因为 MiAuth 会回调到 `yourscheme://`。

### 浏览器标签页未关闭时

示例 Manifest 按照 `flutter_web_auth_2` 的建议，在导出的 `MainActivity` 和 `CallbackActivity` 上都设置了 `android:taskAffinity=""`。

如果默认浏览器不支持 Auth Tab（例如 Chrome 137 之前的版本），使用此设置时，身份验证后浏览器标签页可能仍然打开。身份验证仍会成功，但用户需要手动关闭标签页。`flutter_web_auth_2` 会在浏览器支持 Auth Tab 时使用它，否则会回退到 Custom Tab。在 Chrome 109 上测试的回退情况下，Chrome 会在新任务中启动 `CallbackActivity`，因此它无法关闭留在应用任务中的标签页。

- 如需在回退情况下也关闭标签页，请从 `MainActivity` 和 `CallbackActivity` 中同时移除 `android:taskAffinity=""`。只从其中一个移除没有帮助。Auth Tab 不需要此更改；在 Android 13 和 Chrome 154 上，两种设置都能关闭标签页。
- `taskAffinity=""` 有时用于部分缓解 Android 11（API 30）之前设备上的任务劫持（StrandHogg）。针对这一漏洞，Android 官方建议将 `minSdkVersion` 设为 30 或更高版本。上游讨论请参阅 [flutter_web_auth_2 issue #158](https://github.com/ThexXTURBOXx/flutter_web_auth_2/issues/158)。

### `PlatformException(CANCELED, User canceled login, ...)`

库会将其报告为 `UserCancelledException`。如果用户并未取消但仍发生此问题，常见原因包括：

1. 回调未到达应用。请检查 `CallbackActivity` 是否有匹配的 `<intent-filter>`。
2. PWA 或其他应用拦截了链接。
3. `redirect_uri` 与 client_id 页面上的 `<link rel="redirect_uri">` 不完全匹配，因此 Misskey 没有执行重定向。
