---
sidebar_position: 5
title: 토큰 저장
---

# 토큰 저장

`MisskeyAuthManager`는 여러 계정의 토큰을 저장하고 활성 계정을 관리합니다. 저장은 `TokenStore` 인터페이스를 통해 이루어지며 기본 구현은 `SecureTokenStore`입니다.

## 계정 관리

```dart
final auth = MisskeyAuthManager.defaultInstance();

// 토큰
final current = await auth.currentToken();  // 활성 계정. 없으면 null
final specific = await auth.tokenOf(key);   // 지정한 계정. 없으면 null

// 계정
final accounts = await auth.listAccounts();
await auth.setActive(key);
final active = await auth.getActive();
await auth.clearActive();

// 로그아웃
await auth.signOut(key);  // 한 계정의 토큰 폐기 및 삭제
await auth.signOutAll();  // 모든 계정의 토큰 폐기 및 삭제
```

## 로그아웃 {#signing-out}

로그아웃하면 서버에서 토큰을 폐기한 다음 기기에서 삭제합니다. 폐기하려면 Misskey 2026.9.0 이상이 필요합니다. 이 버전부터 앱 토큰이 `/api/i/revoke-token`을 통해 스스로를 폐기할 수 있습니다. MiAuth 토큰과 OAuth 토큰 모두 권한과 관계없이 폐기할 수 있습니다.

```dart
final result = await auth.signOut(key);
final revocation = result.revocation;
if (revocation == null) {
  // 폐기를 시도하지 않았습니다. result.skipReason을 확인하세요.
} else if (revocation.isInvalidated) {
  // revoked 또는 alreadyInvalid: 서버에서 더 이상 토큰을 사용할 수 없습니다.
} else if (revocation.status == TokenRevocationStatus.unsupported) {
  // 서버가 2026.9.0보다 오래된 버전입니다. 서버에서는 토큰이 계속 유효합니다.
} else {
  // failed: 네트워크 오류, 시간 초과 또는 예상하지 못한 응답입니다.
}
```

### 모드

`mode`를 전달하면 기기의 토큰을 어떻게 처리할지 선택할 수 있습니다.

| `SignOutMode` | 폐기 | 기기에서 삭제 |
|---|---|---|
| `revokeAndDelete`(기본값) | 예 | 항상(폐기 결과와 관계없이) |
| `revokeOrKeep` | 예 | 결과가 `revoked` 또는 `alreadyInvalid`인 경우에만 |
| `localOnly` | 아니요 | 항상 |

`revokeOrKeep`을 사용하면 폐기하지 못한 토큰이 저장된 채로 남으므로 사용자가 나중에 다시 시도할 수 있습니다. 폐기를 지원하지 않는 서버는 항상 `unsupported`를 반환하며, 정지된 계정처럼 서버가 다른 이유로 거부하는 계정은 매번 실패할 수 있습니다. 이러한 계정을 기기에서 제거하려면 `SignOutMode.localOnly`로 다시 로그아웃하세요.

토큰이 저장되어 있지 않거나 저장된 데이터가 손상되는 등의 이유로 읽을 수 없는 경우에는 모든 모드에서 폐기하지 않고 삭제합니다.

### 결과

`signOut`은 `SignOutResult`를 반환하고, `signOutAll`은 `listAccounts` 순서대로 계정마다 하나씩 반환합니다.

| 필드 | 의미 |
|---|---|
| `key` | 대상 계정 |
| `revocation` | `TokenRevocationResult`. 폐기를 시도하지 않았으면 `null` |
| `skipReason` | 폐기를 시도하지 않은 이유: `localOnly`, `noStoredToken`, `unreadableToken` 중 하나. 시도했으면 `null` |
| `deleted` | 기기에서 토큰을 삭제했는지 여부 |

`TokenRevocationResult`에는 다음 필드가 있습니다.

| 필드 | 의미 |
|---|---|
| `status` | `revoked`, `alreadyInvalid`, `unsupported`, `failed` 중 하나 |
| `isInvalidated` | `revoked`와 `alreadyInvalid`일 때 `true` |
| `statusCode` | HTTP 상태. 응답을 받지 못했으면 `null` |
| `errorCode` | `RATE_LIMIT_EXCEEDED`와 같은 Misskey 오류 코드(있는 경우) |
| `error` | `unsupported`와 `failed`의 원인. 오류 응답이면 `TokenRevocationException`, 네트워크 오류나 시간 초과면 `NetworkException`, 읽을 수 없는 응답이면 `ResponseParseException` |

`alreadyInvalid`는 서버가 토큰을 인식하지 못했다는 뜻입니다. 토큰이 이미 폐기되었거나 계정이 삭제된 경우입니다. `revoked`와 같이 취급됩니다.

폐기 실패는 결과로 보고되며 예외로 발생하지 않습니다. 기기에서 토큰을 삭제할 때 발생한 오류는 이전과 마찬가지로 예외로 발생합니다. `signOutAll`은 먼저 모든 계정의 삭제를 시도한 다음 첫 번째 오류를 발생시킵니다.

`deleted`가 `false`가 되는 경우는 두 가지입니다. `revokeOrKeep`이 토큰을 유지한 경우와, 폐기가 진행되는 동안 같은 계정에 새 토큰이 저장된 경우(예: 사용자가 다시 로그인함)입니다. 새 토큰은 폐기된 적이 없으므로 삭제하지 않습니다.

### 시간 초과와 재시도 {#timeout-and-retries}

폐기는 재시도하지 않습니다. `timeout`을 지정하지 않으면 응답하지 않는 요청은 요청 시간 초과까지 기다립니다([시간 초과](#timeouts) 참조). 대기 시간을 제한하려면 `timeout`을 전달하세요.

```dart
await auth.signOut(key, timeout: const Duration(seconds: 5));
await auth.signOutAll(timeout: const Duration(seconds: 5));
```

`signOutAll`은 모든 계정을 병렬로 폐기하며, `timeout`은 작업 전체에 적용됩니다. 시간이 초과된 요청은 `failed`로 보고됩니다. 그래도 서버에서는 토큰이 폐기되었을 수 있으며, 이 경우 다시 로그아웃하면 `alreadyInvalid`가 보고됩니다.

### 매니저 없이 폐기하기

토큰을 직접 저장한다면 `MisskeyTokenRevocationClient`를 직접 사용하세요. 이 클라이언트는 서버에서 토큰을 폐기할 뿐 저장소에는 전혀 접근하지 않습니다.

```dart
final revocation = MisskeyTokenRevocationClient();
final result = await revocation.revoke(
  host: 'misskey.io',
  accessToken: token,
  timeout: const Duration(seconds: 5),
);
if (result.isInvalidated) {
  // 직접 관리하는 저장소에서 토큰을 삭제합니다.
}
```

`revoke`는 예외를 발생시키지 않으며 같은 `TokenRevocationResult`를 반환합니다. 클라이언트는 토큰을 요청 본문에 담아 전송합니다. 직접 만든 `Dio`를 전달하면 해당 인터셉터가 토큰을 볼 수 있으므로 요청 본문을 로그에 기록하지 마세요.

## 시간 초과 {#timeouts}

`MisskeyAuthManager.defaultInstance()`는 기본 시간 초과(연결 10초, 전송 및 수신 각각 20초)를 사용합니다. 변경하려면 `MisskeyAuthManager`를 직접 구성하세요. `MisskeyAuthManager`의 시간 초과는 자체 요청인 `/api/i`와 토큰 폐기에 적용되므로 각 클라이언트에도 전달해야 합니다.

```dart
const timeout = Duration(seconds: 30);
final auth = MisskeyAuthManager(
  miauth: MisskeyMiAuthClient(receiveTimeout: timeout),
  oauth: MisskeyOAuthClient(receiveTimeout: timeout),
  store: const SecureTokenStore(),
  receiveTimeout: timeout,
);
```

각 생성자는 `connectTimeout`, `sendTimeout`, `receiveTimeout`을 받습니다. `dio`도 전달할 수 있습니다. `MisskeyOAuthClient`와 `MisskeyMiAuthClient`는 전달된 `Dio`에도 시간 초과 인수를 적용합니다. `MisskeyTokenRevocationClient`는 시간 초과 인수를 자체 요청에만 적용하고 전달된 `Dio`는 변경하지 않습니다. `MisskeyAuthManager`는 `dio`를 전달받으면 시간 초과 인수를 무시합니다. 이 경우 `Dio`에서 직접 설정하세요. 다른 폐기 클라이언트를 사용하려면 `revocation`으로 전달하세요.

## 모델

```dart
class AccountKey {
  final String host;       // 예: 'misskey.io'
  final String accountId;  // 해당 서버의 사용자 ID
}

class StoredToken {
  final String accessToken;
  final String tokenType;  // 'MiAuth' 또는 'OAuth'
  final String? scope;     // OAuth만 해당
  final Map<String, dynamic>? user;
  final DateTime? createdAt;
}

class AccountEntry {
  final AccountKey key;
  final String? userName;
  final DateTime? createdAt;
}
```

사용자 ID는 서버 내에서만 고유하므로 `AccountKey`는 호스트와 사용자 ID를 조합합니다. 호스트는 설정에 전달한 문자열 그대로 저장되므로, 같은 서버에는 항상 같은 형식(예: 소문자 `misskey.io`)을 사용하세요. 기존 `AccountKey`에 토큰을 저장하면 이전 토큰을 대체합니다.

## `TokenStore`

토큰을 다른 곳에 저장하려면 `TokenStore`를 구현해 `MisskeyAuthManager`에 전달합니다.

```dart
abstract class TokenStore {
  Future<void> upsert(AccountKey key, StoredToken token);
  Future<StoredToken?> read(AccountKey key);
  Future<List<AccountEntry>> list();
  Future<void> delete(AccountKey key);
  Future<void> clearAll();
  Future<void> setActive(AccountKey? key);
  Future<AccountKey?> getActive();
}
```

## `SecureTokenStore`

`SecureTokenStore`는 `flutter_secure_storage`로 토큰을 저장합니다. iOS와 macOS에서는 키체인, Android에서는 Keystore를 사용합니다. 저장 옵션을 변경하려면 직접 생성한 `FlutterSecureStorage`를 전달하세요. misskey_auth는 이 클래스를 재내보내지 않으므로 `flutter_secure_storage`를 종속성에 추가하고 import해야 합니다.

```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const store = SecureTokenStore(
  storage: FlutterSecureStorage(/* 선택적 옵션 */),
);
```

### 동시성

- 쓰기 작업(`upsert`, `delete`, `clearAll`, `setActive`)은 같은 isolate 안에서 인스턴스가 달라도 한 번에 하나씩 실행됩니다. 동시에 써도 인덱스에서 계정이 사라지지 않습니다.
- 읽기는 차단되지 않습니다. 또한 `upsert` 후 `setActive`와 같은 일련의 작업은 원자적으로 처리되지 않습니다.
- 다른 isolate 또는 프로세스의 쓰기 작업과는 상호 배제하지 않습니다.

### `clearAll`이 삭제하는 항목

`clearAll`은 스토어 인덱스에 나열된 계정, 인덱스 자체, 활성 계정 설정을 삭제합니다. 저장 영역 전체를 열거하지는 않습니다. Android에서는 항목 하나의 복호화에 실패해도 `readAll`이 저장 영역 전체를 지울 수 있기 때문입니다. 따라서 이전 버전에서 인덱스에 등록되지 않은 채 남은 토큰은 삭제되지 않습니다.

### 공유 저장 영역 {#shared-storage}

기본 `SecureTokenStore`는 기본 저장 영역을 사용하며, 앱의 다른 코드도 같은 영역을 사용할 수 있습니다. `flutter_secure_storage` 11에서는 `resetOnError`가 기본으로 활성화되어 있어 저장 영역 오류에서 복구할 때 해당 영역의 다른 값도 삭제될 수 있습니다. 같은 저장 영역에 다른 데이터를 보관한다면 설정을 확인하세요. [flutter_secure_storage 변경 기록](https://pub.dev/packages/flutter_secure_storage/changelog)도 참조하세요.
