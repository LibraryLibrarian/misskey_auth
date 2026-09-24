---
sidebar_position: 6
title: 오류 처리
---

# 오류 처리

인증 API는 `MisskeyAuthException`의 하위 클래스를 발생시킵니다. 처리할 예외 유형을 구체적으로 catch하고, 나머지는 `MisskeyAuthException`으로 처리하세요.

```dart
import 'dart:developer';

try {
  await auth.loginWithOAuth(config);
} on UserCancelledException {
  // 사용자가 브라우저를 닫았습니다. 보통 별도 보고가 필요하지 않습니다.
} on OAuthNotSupportedException {
  // 서버가 OAuth를 지원하지 않습니다. 대신 MiAuth를 시도하세요.
} on NetworkException catch (e) {
  // 시간 초과, 연결 없음, TLS 오류 등
  log('Network error', error: e.originalException);
} on MisskeyAuthException catch (e) {
  log('Authentication failed: ${e.message} ${e.details ?? ''}');
}
```

각 예외에는 다음 속성이 있습니다.

- `message`: 간단한 설명
- `details`: 추가 정보(있는 경우)
- `originalException`: 원인이 된 예외(있는 경우)

`message`와 `details`는 로그용입니다. 일본어 메시지도 포함되어 있습니다. 사용자에게는 예외 유형에 따라 앱에서 준비한 문구를 표시하세요.

## 예외 목록

### 공통

| 예외 | 발생 조건 |
|---|---|
| `UserCancelledException` | 사용자가 브라우저를 닫거나 인증을 취소했습니다. [플랫폼 설정](./platform-setup.md)도 참조하세요. |
| `CallbackSchemeErrorException` | 플랫폼 오류 메시지에 콜백이 언급됩니다. 일반적으로 콜백 URL 스킴이 등록되지 않았거나 일치하지 않는다는 뜻입니다. |
| `AuthorizationLaunchException` | 브라우저를 열지 못했거나 플랫폼에서 다른 오류를 보고했습니다. |
| `NetworkException` | 응답을 받지 못한 상태로 요청이 실패했습니다(시간 초과, 연결 없음, TLS 오류 등). `/api/i`가 오류 상태를 반환할 때도 `loginWithOAuth`가 이 예외를 발생시킵니다. |
| `ResponseParseException` | 응답이 예상한 JSON 형식이 아니거나 토큰 또는 사용자 `id`와 같은 필수 필드가 없습니다. |
| `MisskeyAuthException` | 예상하지 못한 오류입니다. 이 표와 아래 표에 나열된 모든 예외의 기본 클래스입니다. |

### OAuth

| 예외 | 발생 조건 |
|---|---|
| `OAuthNotSupportedException` | 서버가 OAuth를 지원하지 않습니다(`/.well-known/oauth-authorization-server`가 404 또는 501을 반환함). |
| `ServerInfoException` | 서버 정보 요청에서 404·501 이외의 오류 상태를 반환했거나, `issuer`가 `https://{host}`와 정확히 일치하지 않거나, authorization endpoint 또는 token endpoint가 HTTPS 절대 URL이 아닙니다. `OAuthNotSupportedException`과 달리 MiAuth로 전환해야 한다는 의미는 아닙니다. |
| `StateMismatchException` | 콜백의 `state`가 없거나 요청과 일치하지 않습니다. |
| `AuthorizationServerErrorException` | 콜백에 `error`가 포함되어 있습니다(예: 사용자가 액세스를 거부했을 때의 `access_denied`). `details`에는 `error`와 `error_description`이 포함됩니다. |
| `AuthorizationCodeMissingException` | 콜백에 authorization code가 없거나 두 개 이상 있습니다. |
| `TokenExchangeException` | token endpoint가 오류를 반환했습니다. 메시지에는 HTTP 상태와 서버 오류가 포함됩니다. |

### MiAuth

| 예외 | 발생 조건 |
|---|---|
| `MiAuthDeniedException` | check API가 `ok: false`를 반환했습니다. 사용자가 액세스를 거부했을 수 있지만, Misskey는 알 수 없는 세션이나 이미 사용된 세션에도 이 값을 반환합니다. |
| `MiAuthSessionInvalidException` | 콜백이 다른 세션에 대한 것이거나 check API가 404 또는 410을 반환했습니다. |
| `MiAuthCheckFailedException` | check API가 그 밖의 오류 상태를 반환했습니다. |

### 현재 버전에서 발생하지 않는 예외

`InvalidAuthConfigException`, `SecureStorageException`, `MiAuthNotSupportedException`은 정의되어 있지만 현재 버전에서는 발생하지 않습니다.

## 저장소 오류

`SecureTokenStore`는 `flutter_secure_storage` 오류를 감싸지 않습니다. 오류는 해당 패키지가 발생시킨 형태(일반적으로 `PlatformException`) 그대로 호출 코드에 전달됩니다. 저장된 데이터가 손상된 경우 읽을 때 `FormatException` 또는 `TypeError`가 발생할 수도 있습니다. 인증 후 토큰을 저장하는 `loginWithOAuth`와 `loginWithMiAuth`를 포함해 토큰을 읽거나 쓰는 `MisskeyAuthManager` 호출 주변에서 이러한 오류를 처리하세요.

`loginWithOAuth`와 `loginWithMiAuth`는 토큰을 저장한 다음 계정을 활성화합니다. 두 번째 단계만 실패하면 토큰은 저장된 채로 남고 계정은 활성화되지 않습니다.

## 재시도

- OAuth 서버 정보 조회와 `/api/i` 호출은 시간 초과, 연결 오류, 기타 전송 오류, HTTP 429·500·502·503·504에서 최대 총 세 번 시도합니다.
- 토큰 교환과 MiAuth check API는 재시도하지 않습니다. authorization code와 MiAuth 세션은 한 번만 사용할 수 있으며, 응답을 받지 못했더라도 서버에서 요청 처리가 완료되었을 수 있습니다. 처음부터 인증을 다시 시작하세요.

## 인증 후 로그인에 실패하는 경우

`loginWithOAuth`는 토큰을 얻은 후 `/api/i`를 호출합니다. 해당 호출이 실패하면 토큰을 저장하지 않고 예외를 발생시킵니다. `loginWithOAuth`와 `loginWithMiAuth`는 사용자 정보에 `id`가 없는 경우에도 토큰을 저장하지 않고 예외를 발생시킵니다.

이 경우 서버는 이미 토큰을 발급했으며 토큰은 서버에서 계속 유효합니다. 라이브러리는 토큰을 폐기하지 않습니다. 사용자는 다시 로그인할 수 있으며, 이때 새 토큰이 발급됩니다.
