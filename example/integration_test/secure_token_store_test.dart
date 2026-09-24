// 実機・エミュレーター上の Keystore / Keychain で SecureTokenStore を検証する
//
// 実行: flutter test integration_test -d <device>
// 端末の既定の保存領域を初期化するため、検証用の端末で実行すること
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:misskey_auth/misskey_auth.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const storage = FlutterSecureStorage();
  const store = SecureTokenStore();
  const unrelatedKey = 'integration_unrelated_key';

  AccountKey account(int i) =>
      AccountKey(host: 'example.test', accountId: 'user$i');
  StoredToken token(int i) => StoredToken(
    accessToken: 'synthetic-$i',
    tokenType: 'MiAuth',
    user: {'username': 'user$i'},
  );

  setUp(() async {
    await storage.deleteAll();
    await storage.write(key: unrelatedKey, value: 'preserve');
  });
  tearDownAll(() => storage.deleteAll());

  testWidgets('stores, reads, and lists a token', (_) async {
    await store.upsert(account(1), token(1));
    expect((await store.read(account(1)))!.accessToken, 'synthetic-1');
    final entries = await store.list();
    expect(entries.single.key, account(1));
    expect(entries.single.userName, 'user1');
  });

  testWidgets('concurrent upserts keep every account in the index', (_) async {
    await Future.wait([
      for (var i = 0; i < 20; i++) store.upsert(account(i), token(i)),
    ]);
    final keys = (await store.list()).map((e) => e.key).toSet();
    expect(keys, {for (var i = 0; i < 20; i++) account(i)});
    for (var i = 0; i < 20; i++) {
      expect((await store.read(account(i)))!.accessToken, 'synthetic-$i');
    }
  });

  testWidgets('writes from separate instances are serialized', (_) async {
    await store.upsert(account(0), token(0));
    await store.setActive(account(0));
    await Future.wait([
      for (var i = 1; i < 10; i++)
        SecureTokenStore(storage: const FlutterSecureStorage())
            .upsert(account(i), token(i)),
      const SecureTokenStore().delete(account(0)),
    ]);
    final keys = (await store.list()).map((e) => e.key).toSet();
    expect(keys, {for (var i = 1; i < 10; i++) account(i)});
    expect(await store.read(account(0)), isNull);
    expect(await store.getActive(), isNull);
  });

  testWidgets('delete clears the active account only when it matches', (
    _,
  ) async {
    await store.upsert(account(1), token(1));
    await store.upsert(account(2), token(2));
    await store.setActive(account(2));
    await store.delete(account(1));
    expect(await store.getActive(), account(2));
    await store.delete(account(2));
    expect(await store.getActive(), isNull);
    expect(await store.list(), isEmpty);
  });

  testWidgets('clearAll removes indexed tokens and keeps other keys', (
    _,
  ) async {
    for (var i = 0; i < 5; i++) {
      await store.upsert(account(i), token(i));
    }
    await store.setActive(account(3));
    await store.clearAll();
    expect(await store.list(), isEmpty);
    expect(await store.getActive(), isNull);
    for (var i = 0; i < 5; i++) {
      expect(await store.read(account(i)), isNull);
    }
    expect(await storage.read(key: unrelatedKey), 'preserve');
  });
}
