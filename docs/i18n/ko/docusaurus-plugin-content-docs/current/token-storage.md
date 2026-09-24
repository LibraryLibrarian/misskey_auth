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
await auth.signOut(key);  // 한 계정의 토큰 삭제
await auth.signOutAll();  // 모든 계정의 토큰 삭제
```

로그아웃은 기기에 저장된 토큰만 삭제합니다. 서버에서 토큰을 폐기하지는 않습니다.

## 시간 초과

`MisskeyAuthManager.defaultInstance()`는 기본 시간 초과(연결 10초, 전송 및 수신 각각 20초)를 사용합니다. 변경하려면 manager를 직접 구성하세요. manager의 시간 초과는 자체 `/api/i` 요청에만 적용되므로 각 클라이언트에도 전달해야 합니다.

```dart
const timeout = Duration(seconds: 30);
final auth = MisskeyAuthManager(
  miauth: MisskeyMiAuthClient(receiveTimeout: timeout),
  oauth: MisskeyOAuthClient(receiveTimeout: timeout),
  store: const SecureTokenStore(),
  receiveTimeout: timeout,
);
```

각 생성자는 `connectTimeout`, `sendTimeout`, `receiveTimeout`을 받습니다. `dio`도 전달할 수 있습니다. 클라이언트는 전달된 `Dio`에도 시간 초과 인수를 적용하지만, `MisskeyAuthManager`는 `dio`를 전달받으면 시간 초과 인수를 무시합니다. 이 경우 `Dio`에서 직접 설정하세요.

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

`SecureTokenStore`는 `flutter_secure_storage`로 토큰을 저장합니다. iOS에서는 키체인, Android에서는 Keystore를 사용합니다. 저장 옵션을 변경하려면 `FlutterSecureStorage`를 전달하세요. misskey_auth는 이 클래스를 재내보내지 않으므로 `flutter_secure_storage`를 종속성에 추가하고 import해야 합니다.

```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const store = SecureTokenStore(
  storage: FlutterSecureStorage(/* 선택적 옵션 */),
);
```

### 동시성

- 쓰기 작업(`upsert`, `delete`, `clearAll`, `setActive`)은 인스턴스 간에도 isolate 안에서 한 번에 하나씩 실행됩니다. 동시에 써도 인덱스에서 계정이 사라지지 않습니다.
- 읽기는 차단되지 않으며 `upsert` 후 `setActive`와 같은 일련의 작업은 원자적으로 처리되지 않습니다.
- 다른 isolate 또는 프로세스의 쓰기 작업과는 조정되지 않습니다.

### `clearAll`이 삭제하는 항목

`clearAll`은 스토어 인덱스에 나열된 계정, 인덱스 자체, 활성 계정 설정을 삭제합니다. 저장 영역 전체를 열거하지는 않습니다. Android에서는 항목 하나의 복호화에 실패해도 `readAll`이 저장 영역 전체를 지울 수 있기 때문입니다. 따라서 이전 버전에서 인덱스에 등록되지 않은 채 남은 토큰은 삭제되지 않습니다.

### 공유 저장 영역 {#shared-storage}

기본 `SecureTokenStore`는 기본 저장 영역을 사용하며, 앱의 다른 코드도 같은 영역을 사용할 수 있습니다. `flutter_secure_storage` 11에서는 `resetOnError`가 기본으로 활성화되어 있어 저장 영역 오류에서 복구할 때 해당 영역의 다른 값도 삭제될 수 있습니다. 같은 저장 영역에 다른 데이터를 보관한다면 설정을 확인하세요. [flutter_secure_storage 변경 기록](https://pub.dev/packages/flutter_secure_storage/changelog)도 참조하세요.
