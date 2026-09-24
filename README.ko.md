[English](README.md) | [日本語](README.ja.md) | [简体中文](README.zh-Hans.md) | [Deutsch](README.de.md) | [Français](README.fr.md) | 한국어

# misskey_auth

<p align="center">
  <img src="https://raw.githubusercontent.com/librarylibrarian/misskey_auth/main/assets/demo_thumb.gif" alt="Demo" width="200" />
</p>

[![License](https://img.shields.io/badge/License-BSD_3--Clause-blue.svg)](https://opensource.org/licenses/BSD-3-Clause)

[Misskey](https://misskey-hub.net/) 서버 인증을 위한 Flutter 라이브러리입니다. OAuth 2.0과 MiAuth를 모두 지원하며, 여러 계정의 토큰을 저장할 수 있습니다.

## 특징

- Misskey 서버의 OAuth 2.0 인증(v2023.9.0 이상)
- 이전 서버를 위한 MiAuth 인증
- 외부 브라우저에서 인증(임베디드 WebView를 사용하지 않음)
- PKCE (Proof Key for Code Exchange)
- 사용자 지정 URL 스킴을 통한 앱 콜백
- `flutter_secure_storage`를 사용한 안전한 토큰 저장
- 여러 계정의 토큰 저장 및 활성 계정 전환
- 인증 흐름 실행과 토큰 저장을 중개하는 고수준 API `MisskeyAuthManager`
- iOS 및 Android

## 요구 사항

- Flutter 3.47.1 이상, Dart 3.13.1 이상 4.0 미만
- Android API 24 이상, compileSdk 37 이상
- iOS 15 이상

이전 버전에서 업그레이드하는 경우 먼저 [업그레이드 시 주의 사항](https://librarylibrarian.github.io/misskey_auth/ko/upgrading)을 읽어 주세요. Android에서는 다시 로그인해야 합니다.

## 설치

```yaml
dependencies:
  misskey_auth: ^0.2.0-beta.1
```

## 빠른 시작

```dart
import 'package:misskey_auth/misskey_auth.dart';

final auth = MisskeyAuthManager.defaultInstance();

// OAuth (Misskey v2023.9.0 이상)
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

// MiAuth (이전 서버에서도 동작)
final miKey = await auth.loginWithMiAuth(
  MisskeyMiAuthConfig(
    host: 'misskey.io',
    appName: 'Your App',
    callbackScheme: 'yourscheme',
    permissions: ['read:account', 'write:notes'],
  ),
  setActive: true,
);

// 활성 계정의 저장된 토큰 읽기
final current = await auth.currentToken();
```

이 코드를 사용하려면 다음 두 가지가 필요합니다.

1. **client_id 페이지(OAuth만 해당).** `redirect_uri`를 `<link rel="redirect_uri">`에 명시한 HTTPS 페이지를 공개합니다. [client_id 페이지](https://librarylibrarian.github.io/misskey_auth/ko/client-id-page)를 참조하세요.
2. **앱에 사용자 지정 URL 스킴 등록.** iOS에서는 `Info.plist`에, Android에서는 `flutter_web_auth_2`의 `CallbackActivity`에 `yourscheme`을 추가합니다. [플랫폼 설정](https://librarylibrarian.github.io/misskey_auth/ko/platform-setup)을 참조하세요.

## 문서

- 가이드: https://librarylibrarian.github.io/misskey_auth/ko/
  - [client_id 페이지](https://librarylibrarian.github.io/misskey_auth/ko/client-id-page)
  - [플랫폼 설정](https://librarylibrarian.github.io/misskey_auth/ko/platform-setup)
  - [OAuth와 MiAuth](https://librarylibrarian.github.io/misskey_auth/ko/oauth-and-miauth)
  - [토큰 저장](https://librarylibrarian.github.io/misskey_auth/ko/token-storage)
  - [오류 처리](https://librarylibrarian.github.io/misskey_auth/ko/error-handling)
  - [업그레이드 시 주의 사항](https://librarylibrarian.github.io/misskey_auth/ko/upgrading)
- API 참조: https://pub.dev/documentation/misskey_auth/latest/
- 변경 이력: [CHANGELOG.md](CHANGELOG.md)
- Misskey 문서: [OAuth](https://misskey-hub.net/ko/docs/for-developers/api/token/oauth/) / [MiAuth](https://misskey-hub.net/ko/docs/for-developers/api/token/miauth/)

## 라이선스

이 프로젝트는 司書 (LibraryLibrarian)가 3-Clause BSD License에 따라 공개합니다. 자세한 내용은 [LICENSE](LICENSE)를 참조하세요.
