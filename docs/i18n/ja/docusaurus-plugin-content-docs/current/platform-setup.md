---
sidebar_position: 3
title: プラットフォーム設定
---

# プラットフォーム設定

認証は外部ブラウザで行います。認証が終わるとブラウザがアプリのカスタムスキームの URL を開き、OS がその URL をアプリに渡します。スキームの登録はアプリ側で行います。ライブラリが Manifest や `Info.plist` に追加することはありません。

iOS（`CFBundleURLSchemes`）と Android（`<data android:scheme="...">`）には同じスキーム名を登録してください。完全一致が必要です。

## iOS

`ios/Runner/Info.plist` にスキームを追加します。

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

`android/app/src/main/AndroidManifest.xml` に、`flutter_web_auth_2` の `CallbackActivity` を追加します。

```xml
<activity
    android:name="com.linusu.flutter_web_auth_2.CallbackActivity"
    android:exported="true"
    android:taskAffinity="">
    <intent-filter>
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.DEFAULT" />
        <category android:name="android.intent.category.BROWSABLE" />
        <!-- 最小構成: スキームのみ -->
        <data android:scheme="yourscheme" />
        <!-- 任意（OAuth のみ）: ブラウザが最終的に開くカスタムスキームの URL に合わせて host/path を制限する。
             MiAuth は host/path のない `yourscheme://` に戻るため、MiAuth も使う場合はスキームのみの指定を残す -->
        <!-- <data android:scheme="yourscheme" android:host="oauth" android:path="/callback" /> -->
    </intent-filter>
</activity>
```

設定の全体は [`example/android/app/src/main/AndroidManifest.xml`](https://github.com/LibraryLibrarian/misskey_auth/blob/main/example/android/app/src/main/AndroidManifest.xml) にあります。Android の設定はこのファイルを基準にしてください。

注意点:

- `<intent-filter>` の `android:label` 属性は省略できます。
- Android 12 以降（API 31 以上）では、`intent-filter` を持つ Activity に `android:exported="true"` の指定が必要です。
- ネットワーク通信を行うアプリでは、`android/app/src/main/AndroidManifest.xml` の `<manifest>` 直下に `<uses-permission android:name="android.permission.INTERNET" />` を宣言してください。`debug` または `profile` 側の Manifest だけの宣言は release ビルドに適用されません。
- intent-filter を host や path で制限する場合は、ブラウザが最終的に開くカスタムスキームの URL（`redirect_uri` そのもの、または中継ページの転送先の URL）に合わせてください。MiAuth も使う場合は、MiAuth が `yourscheme://` に戻るため制限しないでください。

### ブラウザのタブが残る場合

サンプルの Manifest では、`flutter_web_auth_2` の推奨に従い、exported な `MainActivity` と `CallbackActivity` の両方に `android:taskAffinity=""` を設定しています。

この設定では、既定のブラウザが Auth Tab に対応していない場合（例: Chrome 137 未満）、認証後にブラウザのタブが残ることがあります。認証自体は成功しますが、ユーザーがタブを閉じる必要があります。`flutter_web_auth_2` はブラウザが Auth Tab に対応していれば Auth Tab を使い、対応していなければ Custom Tab にフォールバックします。Chrome 109 で確認したフォールバック時の経路では、Chrome が `CallbackActivity` を新しいタスクで起動するため、アプリのタスクに残ったタブを閉じられません。

- フォールバック時もタブを閉じるには、`MainActivity` と `CallbackActivity` の両方から `android:taskAffinity=""` を外してください。片方だけ外しても改善しません。Auth Tab ではこの変更は不要です。Android 13・Chrome 154 では、どちらの設定でもタブが閉じました。
- `taskAffinity=""` は、Android 11（API 30）より前の端末でのタスク乗っ取り（StrandHogg）への部分的な対策として使われることがあります。この脆弱性に対する Android の推奨は `minSdkVersion` を 30 以上にすることです。経緯は [flutter_web_auth_2 の issue #158](https://github.com/ThexXTURBOXx/flutter_web_auth_2/issues/158) を参照してください。

### `PlatformException(CANCELED, User canceled login, ...)`

ライブラリはこれを `UserCancelledException` として報告します。ユーザーがキャンセルしていないのに発生する場合、よくある原因は次のとおりです。

1. コールバックがアプリに届いていない。`CallbackActivity` に一致する `<intent-filter>` があるか確認してください。
2. PWA や別のアプリがリンクを横取りした。
3. `redirect_uri` が client_id ページの `<link rel="redirect_uri">` と完全一致せず、Misskey がリダイレクトしなかった。
