---
sidebar_position: 1
slug: /
title: 시작하기
---

# 시작하기

misskey_auth는 [Misskey](https://misskey-hub.net/ko/) 서버 인증을 위한 Flutter 라이브러리입니다. OAuth 2.0과 MiAuth를 모두 지원하며 여러 계정의 토큰을 저장할 수 있습니다.

## 주요 기능

- Misskey 서버의 OAuth 2.0 인증(v2023.9.0 이상)
- 이전 서버를 위한 MiAuth 인증
- 외부 브라우저에서 인증(임베디드 WebView를 사용하지 않음)
- PKCE(Proof Key for Code Exchange)
- 사용자 지정 URL 스킴을 통한 앱 콜백
- `flutter_secure_storage`를 사용한 안전한 토큰 저장
- 여러 계정의 토큰 저장 및 활성 계정 전환
- 인증을 수행하고 토큰을 저장하는 고수준 API `MisskeyAuthManager`
- iOS 및 Android

## 요구 사항

- Flutter 3.47.1 이상, Dart 3.13.1 이상 4.0 미만
- Android API 24 이상, compileSdk 37 이상
- iOS 15 이상

이전 버전에서 업그레이드하는 경우 먼저 [업그레이드](./upgrading.md)를 읽어 주세요. Android에서는 사용자가 다시 로그인해야 합니다.

## 설치

`pubspec.yaml`에 패키지를 추가합니다.

```yaml
dependencies:
  misskey_auth: ^0.2.0-beta.2
```

그런 다음 패키지를 가져옵니다.

```bash
flutter pub get
```

## 빠른 시작

인증은 세 단계로 진행합니다.

1. **client_id 페이지를 게시합니다(OAuth만 해당).** Misskey는 이 HTTPS 페이지를 가져와 앱의 redirect URI를 확인합니다. [client_id 페이지](./client-id-page.md)를 참조하세요.
2. **앱에 사용자 지정 URL 스킴을 등록합니다.** 브라우저는 이 스킴을 통해 앱으로 돌아옵니다. [플랫폼 설정](./platform-setup.md)을 참조하세요.
3. **Dart에서 인증 흐름을 실행합니다.**

```dart
import 'package:misskey_auth/misskey_auth.dart';

final auth = MisskeyAuthManager.defaultInstance();

// OAuth(Misskey v2023.9.0 이상)
final oauthKey = await auth.loginWithOAuth(
  MisskeyOAuthConfig(
    host: 'misskey.io',
    clientId: 'https://yourpage/yourapp/',
    redirectUri: 'yourscheme://oauth/callback',
    scope: 'read:account write:notes',
    callbackScheme: 'yourscheme',
  ),
  setActive: true,
);

// MiAuth(이전 서버에서도 동작)
final miKey = await auth.loginWithMiAuth(
  MisskeyMiAuthConfig(
    host: 'misskey.io',
    appName: 'Your App',
    callbackScheme: 'yourscheme',
    permissions: ['read:account', 'write:notes'],
    iconUrl: 'https://example.com/icon.png',
  ),
  setActive: true,
);

// 활성 계정의 저장된 토큰 읽기
final current = await auth.currentToken();
print(current?.accessToken);
```

`MisskeyAuthManager`는 각 토큰을 `SecureTokenStore`에 저장합니다. 토큰을 직접 관리하려면 `MisskeyOAuthClient` 또는 `MisskeyMiAuthClient`를 사용하세요. [OAuth와 MiAuth](./oauth-and-miauth.md)를 참조하세요.

## 다음 단계

- [client_id 페이지](./client-id-page.md): Misskey가 OAuth에 요구하는 페이지
- [플랫폼 설정](./platform-setup.md): iOS 및 Android 설정
- [OAuth와 MiAuth](./oauth-and-miauth.md): 두 방식의 차이와 토큰 저장 여부에 따른 예제
- [토큰 저장](./token-storage.md): 여러 계정, `TokenStore`, `SecureTokenStore`
- [오류 처리](./error-handling.md): 라이브러리에서 발생하는 예외
- [pub.dev API 참조](https://pub.dev/documentation/misskey_auth/latest/)

## 예제 앱

저장소의 [`example/`](https://github.com/LibraryLibrarian/misskey_auth/tree/main/example)에 예제 앱이 있습니다. 이 앱은 `https://librarylibrarian.github.io/misskey_auth/example/`에 게시된 client_id 페이지를 사용합니다. 해당 페이지는 예제를 시험할 때만 사용하고, 앱에는 자체 client_id 페이지를 게시하세요.
