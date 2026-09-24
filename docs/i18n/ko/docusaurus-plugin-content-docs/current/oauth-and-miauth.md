---
sidebar_position: 4
title: OAuth와 MiAuth
---

# OAuth와 MiAuth

Misskey에서 앱이 액세스 토큰을 얻는 방법은 두 가지입니다.

| | OAuth 2.0 | MiAuth |
|---|---|---|
| 지원 서버 | Misskey v2023.9.0 이상 | 이전 서버 포함 |
| client_id 페이지 | 필요(HTTPS) | 필요 없음 |
| 브라우저의 복귀 위치 | client_id 페이지에 나열된 `redirect_uri` | `yourscheme://`(스킴만) |
| 설정 클래스 | `MisskeyOAuthConfig` | `MisskeyMiAuthConfig` |

두 방식 모두 외부 브라우저를 열고 사용자 지정 URL 스킴을 통해 앱으로 돌아오므로 [플랫폼 설정](./platform-setup.md)이 필요합니다.

서버의 OAuth 지원 여부는 `MisskeyOAuthClient().getOAuthServerInfo(host)`를 호출해 확인할 수 있습니다. OAuth를 지원하지 않는 서버에서는 `null`을 반환합니다. 이 경우 `authenticate`와 `loginWithOAuth`는 `OAuthNotSupportedException`을 발생시키므로 MiAuth로 전환할 수 있습니다.

## 설정

### `MisskeyOAuthConfig`

| 매개변수 | 설명 |
|---|---|
| `host` | Misskey 서버 호스트(예: `misskey.io`) |
| `clientId` | [client_id 페이지](./client-id-page.md)의 URL |
| `redirectUri` | client_id 페이지에 나열된 redirect URI(예: `yourscheme://oauth/callback`) |
| `scope` | 공백으로 구분된 스코프(예: `read:account write:notes`) |
| `callbackScheme` | 앱의 사용자 지정 스킴입니다. 필수이지만 `redirectUri`가 `http(s)` 중계 페이지일 때만 사용하며, 그 외에는 `redirectUri`의 스킴을 사용합니다. |

### `MisskeyMiAuthConfig`

| 매개변수 | 설명 |
|---|---|
| `host` | Misskey 서버 호스트 |
| `appName` | 사용자에게 표시할 앱 이름 |
| `callbackScheme` | 앱의 사용자 지정 스킴입니다. Misskey는 브라우저를 `yourscheme://`로 리디렉션합니다. |
| `permissions` | 요청할 권한(예: `['read:account', 'write:notes']`). 선택 사항 |
| `iconUrl` | 사용자에게 표시할 앱 아이콘 URL. 선택 사항 |

## 토큰을 저장하지 않는 경우

`MisskeyOAuthClient`와 `MisskeyMiAuthClient`는 인증 흐름을 실행하고 토큰을 반환합니다. 토큰은 저장하지 않습니다.

### OAuth

```dart
import 'package:misskey_auth/misskey_auth.dart';

final oauthClient = MisskeyOAuthClient();
final token = await oauthClient.authenticate(
  MisskeyOAuthConfig(
    host: 'misskey.io',
    clientId: 'https://yourpage/yourapp/',
    redirectUri: 'yourscheme://oauth/callback',
    scope: 'read:account write:notes',
    callbackScheme: 'yourscheme',
  ),
);
print(token?.accessToken);
```

### MiAuth

```dart
import 'package:misskey_auth/misskey_auth.dart';

final miClient = MisskeyMiAuthClient();
final result = await miClient.authenticate(
  MisskeyMiAuthConfig(
    host: 'misskey.io',
    appName: 'Your App',
    callbackScheme: 'yourscheme',
    permissions: ['read:account', 'write:notes'],
    iconUrl: 'https://example.com/icon.png', // 선택 사항
  ),
);
print(result.token);
print(result.user); // 서버가 반환한 경우 사용자 정보
```

## 토큰을 저장하는 경우

`MisskeyAuthManager`는 인증 흐름을 실행하고 `TokenStore`에 토큰을 저장합니다. `MisskeyAuthManager.defaultInstance()`는 `SecureTokenStore`를 사용합니다. 로그인할 때마다 계정을 식별하는 `AccountKey`를 반환합니다.

### OAuth

```dart
import 'package:misskey_auth/misskey_auth.dart';

final auth = MisskeyAuthManager.defaultInstance();
final key = await auth.loginWithOAuth(
  MisskeyOAuthConfig(
    host: 'misskey.io',
    clientId: 'https://yourpage/yourapp/',
    redirectUri: 'yourscheme://oauth/callback',
    scope: 'read:account write:notes',
    callbackScheme: 'yourscheme',
  ),
  setActive: true,
);
final current = await auth.currentToken();
```

OAuth 인증 후 manager는 새 토큰으로 `/api/i`를 호출해 계정 ID를 확인합니다.

### MiAuth

```dart
import 'package:misskey_auth/misskey_auth.dart';

final auth = MisskeyAuthManager.defaultInstance();
final key = await auth.loginWithMiAuth(
  MisskeyMiAuthConfig(
    host: 'misskey.io',
    appName: 'Your App',
    callbackScheme: 'yourscheme',
    permissions: ['read:account', 'write:notes'],
    iconUrl: 'https://example.com/icon.png',
  ),
  setActive: true, // 이 계정도 활성 계정으로 설정
);
final current = await auth.currentToken();
```

MiAuth는 토큰과 함께 사용자 정보도 반환하며, manager는 그 정보의 `id`를 계정 ID로 사용합니다.

## 하나의 앱에서 두 방식 모두 지원하기

- `Info.plist`와 `AndroidManifest.xml`에 `yourscheme`과 같은 스킴 하나를 등록하면 OAuth와 MiAuth에서 함께 사용할 수 있습니다.
- MiAuth는 스킴만(`yourscheme://`)으로 콜백합니다. MiAuth용으로 `yourscheme://oauth/callback`과 같은 경로를 준비할 필요가 없습니다.
- Android에서는 [플랫폼 설정](./platform-setup.md#android)의 스킴만 지정하는 intent-filter를 사용하세요. host나 path로 제한된 필터를 사용하면 MiAuth 콜백이 앱에 전달되지 않습니다.

## 관련 문서

- [Misskey OAuth 문서](https://misskey-hub.net/ko/docs/for-developers/api/token/oauth/)
- [Misskey MiAuth 문서](https://misskey-hub.net/ko/docs/for-developers/api/token/miauth/)
