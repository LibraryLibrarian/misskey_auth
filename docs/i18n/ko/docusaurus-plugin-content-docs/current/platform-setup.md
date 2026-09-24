---
sidebar_position: 3
title: 플랫폼 설정
---

# 플랫폼 설정

인증은 외부 브라우저에서 진행됩니다. 인증이 끝나면 브라우저가 앱의 사용자 지정 스킴 URL을 열고 OS가 해당 URL을 앱에 전달합니다. 스킴은 앱에 등록해야 합니다. 라이브러리가 Manifest나 `Info.plist`에 추가하지는 않습니다.

iOS(`CFBundleURLSchemes`)와 Android(`<data android:scheme="...">`)에 같은 스킴 문자열을 등록하세요. 두 값은 정확히 일치해야 합니다.

## iOS

`ios/Runner/Info.plist`에 스킴을 추가합니다.

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

`android/app/src/main/AndroidManifest.xml`에 `flutter_web_auth_2`의 `CallbackActivity`를 추가합니다.

```xml
<activity
    android:name="com.linusu.flutter_web_auth_2.CallbackActivity"
    android:exported="true"
    android:taskAffinity="">
    <intent-filter>
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.DEFAULT" />
        <category android:name="android.intent.category.BROWSABLE" />
        <!-- 최소 설정: 스킴만 지정 -->
        <data android:scheme="yourscheme" />
        <!-- 선택 사항(OAuth만 해당): 브라우저가 마지막으로 여는 사용자 지정 스킴 URL에 맞게 host/path를 제한합니다.
             MiAuth는 host/path가 없는 `yourscheme://`로 돌아오므로 MiAuth도 사용한다면 스킴만 지정하는 필터를 유지하세요. -->
        <!-- <data android:scheme="yourscheme" android:host="oauth" android:path="/callback" /> -->
    </intent-filter>
</activity>
```

전체 설정은 [`example/android/app/src/main/AndroidManifest.xml`](https://github.com/LibraryLibrarian/misskey_auth/blob/main/example/android/app/src/main/AndroidManifest.xml)에 있습니다. Android 설정은 이 파일을 기준으로 삼으세요.

참고 사항:

- `<intent-filter>`의 `android:label` 속성은 생략할 수 있습니다.
- Android 12(API 31) 이상에서는 `intent-filter`가 있는 Activity에 `android:exported="true"`를 지정해야 합니다.
- 네트워크 요청을 하는 앱은 `android/app/src/main/AndroidManifest.xml`의 `<manifest>` 바로 아래에 `<uses-permission android:name="android.permission.INTERNET" />`를 선언해야 합니다. `debug` 또는 `profile` Manifest에만 선언하면 release 빌드에 적용되지 않습니다.
- intent-filter를 host나 path로 제한하는 경우 브라우저가 마지막으로 여는 사용자 지정 스킴 URL, 즉 `redirect_uri` 자체 또는 중계 페이지가 전달하는 URL에 맞추세요. MiAuth도 사용한다면 MiAuth는 `yourscheme://`로 콜백하므로 제한하지 마세요.

### 브라우저 탭이 계속 열려 있는 경우

예제 Manifest는 `flutter_web_auth_2` 권장 사항에 따라 내보내기된 `MainActivity`와 `CallbackActivity` 모두에 `android:taskAffinity=""`를 설정합니다.

이 설정에서는 기본 브라우저가 Auth Tab을 지원하지 않는 경우(예: Chrome 137 미만) 인증 후에도 브라우저 탭이 열려 있을 수 있습니다. 인증은 성공하지만 사용자가 탭을 닫아야 합니다. `flutter_web_auth_2`는 브라우저가 지원하면 Auth Tab을 사용하고, 지원하지 않으면 Custom Tab으로 대체합니다. Chrome 109에서 확인한 대체 경로에서는 Chrome이 `CallbackActivity`를 새 작업에서 실행하므로 앱 작업에 남은 탭을 닫을 수 없습니다.

- 대체 경로에서도 탭을 닫으려면 `MainActivity`와 `CallbackActivity` 양쪽에서 `android:taskAffinity=""`를 제거하세요. 한쪽에서만 제거해도 해결되지 않습니다. Auth Tab에서는 이 변경이 필요 없습니다. Android 13 및 Chrome 154에서는 어느 설정에서나 탭이 닫혔습니다.
- `taskAffinity=""`는 Android 11(API 30) 이전 기기의 작업 탈취(StrandHogg)에 대한 부분적인 완화책으로 사용되기도 합니다. 이 취약점에 대한 Android 권장 사항은 `minSdkVersion`을 30 이상으로 설정하는 것입니다. 관련 내용은 [flutter_web_auth_2 issue #158](https://github.com/ThexXTURBOXx/flutter_web_auth_2/issues/158)을 참조하세요.

### `PlatformException(CANCELED, User canceled login, ...)`

라이브러리는 이를 `UserCancelledException`으로 보고합니다. 사용자가 취소하지 않았는데도 발생한다면 일반적인 원인은 다음과 같습니다.

1. 콜백이 앱에 전달되지 않았습니다. `CallbackActivity`에 일치하는 `<intent-filter>`가 있는지 확인하세요.
2. PWA 또는 다른 앱이 링크를 가로챘습니다.
3. `redirect_uri`가 client_id 페이지의 `<link rel="redirect_uri">`와 완전히 일치하지 않아 Misskey가 리디렉션하지 않았습니다.
