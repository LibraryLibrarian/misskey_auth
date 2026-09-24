import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:misskey_auth/misskey_auth.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const key = AccountKey(host: 'example.test', accountId: 'user1');
  const other = AccountKey(host: 'example.test', accountId: 'user2');
  const store = SecureTokenStore();
  setUp(
    () => FlutterSecureStorage.setMockInitialValues({
      'misskey_token::example.test::user1': '{"accessToken":"synthetic-token","tokenType":"MiAuth","user":{"username":"sample"}}',
      'misskey_accounts_index': '[{"host":"example.test","accountId":"user1"}]',
      'misskey_active_account': '{"host":"example.test","accountId":"user1"}',
      'unrelated_key': 'preserve',
    }),
  );
  test('reads existing application JSON and account metadata', () async {
    expect((await store.read(key))!.accessToken, 'synthetic-token');
    expect((await store.list()).single.userName, 'sample');
    expect(await store.getActive(), key);
  });
  test('updates and adds accounts without duplicate index entries', () async {
    const token = StoredToken(
      accessToken: 'replacement',
      tokenType: 'OAuth',
      scope: 'read',
    );
    await store.upsert(key, token);
    await store.upsert(other, token);
    expect((await store.read(key))!.tokenType, 'OAuth');
    expect((await store.list()).map((e) => e.key), [key, other]);
    await store.setActive(other);
    expect(await store.getActive(), other);
  });
  test(
    'delete clears matching active account and preserves unrelated storage',
    () async {
      await store.delete(key);
      expect(await store.read(key), isNull);
      expect(await store.list(), isEmpty);
      expect(await store.getActive(), isNull);
      expect(await store.storage.read(key: 'unrelated_key'), 'preserve');
    },
  );
  test('clearAll preserves keys outside this library', () async {
    await store.clearAll();
    expect(await store.list(), isEmpty);
    expect(await store.getActive(), isNull);
    expect(await store.storage.read(key: 'unrelated_key'), 'preserve');
  });
  test('propagates native read failures', () async {
    final failing = SecureTokenStore(storage: FailingStorage());
    await expectLater(failing.read(key), throwsA(isA<PlatformException>()));
  });

  group('write operations', () {
    const token = StoredToken(accessToken: 'synthetic', tokenType: 'MiAuth');
    const third = AccountKey(host: 'example.test', accountId: 'user3');

    /// インデックスを読んだ後に遅らせ、古い値を持ったまま書き込みが重なる状況を作る
    Future<void> slowIndexRead(String operation, String? key) async {
      if (operation == 'afterRead' && key == 'misskey_accounts_index') {
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }
    }

    test('concurrent upserts keep every account in the index', () async {
      final store = SecureTokenStore(
        storage: ControlledStorage(before: slowIndexRead),
      );
      await Future.wait([
        store.upsert(other, token),
        store.upsert(third, token),
      ]);
      expect((await store.list()).map((e) => e.key), [key, other, third]);
    });

    test('are serialized across store instances', () async {
      final storage = ControlledStorage(before: slowIndexRead);
      await Future.wait([
        SecureTokenStore(storage: storage).upsert(other, token),
        SecureTokenStore(storage: storage).delete(key),
      ]);
      expect((await store.list()).map((e) => e.key), [other]);
      expect(await store.getActive(), isNull);
    });

    test('a failed write does not block later writes', () async {
      final failing = SecureTokenStore(
        storage: ControlledStorage(
          before: (operation, k) async {
            if (operation == 'write' && k == other.storageKey()) {
              throw PlatformException(code: 'StorageError');
            }
          },
        ),
      );
      await expectLater(
        failing.upsert(other, token),
        throwsA(isA<PlatformException>()),
      );
      await failing.upsert(third, token);
      expect(await store.read(third), isNotNull);
      // インデックスを先に書くため、失敗した分も一覧から辿れる
      expect((await store.list()).map((e) => e.key), [key, other, third]);
      expect(await store.read(other), isNull);
    });

    test('clearAll never enumerates the whole storage', () async {
      // Android の readAll は復号失敗時に保存領域全体を消去し得るため使わない
      final guarded = SecureTokenStore(
        storage: ControlledStorage(
          before: (operation, _) async {
            if (operation == 'readAll') fail('readAll must not be called');
          },
        ),
      );
      await guarded.clearAll();
      expect(await store.list(), isEmpty);
      expect(await store.read(key), isNull);
      expect(await store.storage.read(key: 'unrelated_key'), 'preserve');
    });
  });
}

class FailingStorage extends FlutterSecureStorage {
  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    throw PlatformException(code: 'StorageError');
  }
}

/// 各操作の直前に [before] を呼ぶストレージ（遅延・失敗の注入用）
class ControlledStorage extends FlutterSecureStorage {
  ControlledStorage({this.before});

  final Future<void> Function(String operation, String? key)? before;

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    await before?.call('read', key);
    final value = await super.read(key: key);
    await before?.call('afterRead', key);
    return value;
  }

  @override
  Future<Map<String, String>> readAll({
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    await before?.call('readAll', null);
    return super.readAll();
  }

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    await before?.call('write', key);
    return super.write(key: key, value: value);
  }

  @override
  Future<void> delete({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    await before?.call('delete', key);
    return super.delete(key: key);
  }
}
