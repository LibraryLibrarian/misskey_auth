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
