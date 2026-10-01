import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:misskey_auth/misskey_auth.dart';

import 'support/fakes.dart';

const _a = AccountKey(host: 'a.test', accountId: 'userA');
const _b = AccountKey(host: 'a.test', accountId: 'userB');
const _c = AccountKey(host: 'c.test', accountId: 'userC');

/// 各失効結果を返すサーバー応答
final _responses = <TokenRevocationStatus, ResponseBody Function()>{
  TokenRevocationStatus.revoked: () => ResponseBody.fromString('', 204),
  TokenRevocationStatus.alreadyInvalid: () =>
      _apiError(401, 'AUTHENTICATION_FAILED'),
  TokenRevocationStatus.unsupported: () => _apiError(400, 'ACCESS_DENIED'),
  TokenRevocationStatus.failed: () => _apiError(500, 'INTERNAL_ERROR'),
};

ResponseBody _apiError(int status, String code) => jsonBody({
  'error': {'message': 'm', 'code': code, 'id': 'x'},
}, status);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late MemoryTokenStore store;
  late Dio dio;
  late MisskeyAuthManager auth;
  late List<RequestOptions> requests;

  /// 失効リクエストへの応答。既定は 204
  late FutureOr<ResponseBody> Function(RequestOptions) respond;

  setUp(() {
    store = MemoryTokenStore();
    requests = [];
    respond = (_) => ResponseBody.fromString('', 204);
    dio = Dio()
      ..httpClientAdapter = StubAdapter((options) {
        requests.add(options);
        return respond(options);
      });
    auth = MisskeyAuthManager(
      miauth: MisskeyMiAuthClient(),
      oauth: MisskeyOAuthClient(),
      store: store,
      dio: dio,
    );
  });
  tearDown(() => dio.close(force: true));

  /// 失効したトークン（リクエストの `token`）
  List<Object?> revokedTokens() => [for (final r in requests) r.data['token']];

  group('signOut', () {
    test('revokes and deletes by default', () async {
      store.seed(_a, 'tokenA');
      final result = await auth.signOut(_a);
      expect(revokedTokens(), ['tokenA']);
      expect(
        requests.single.uri.toString(),
        'https://a.test/api/i/revoke-token',
      );
      expect(result.key, _a);
      expect(result.revocation!.status, TokenRevocationStatus.revoked);
      expect(result.skipReason, isNull);
      expect(result.deleted, isTrue);
      expect(store.tokens, isEmpty);
    });

    test('localOnly deletes without reading or revoking', () async {
      store.seed(_a, 'tokenA');
      final result = await auth.signOut(_a, mode: SignOutMode.localOnly);
      expect(requests, isEmpty);
      expect(store.calls, ['delete:userA']);
      expect(result.revocation, isNull);
      expect(result.skipReason, RevocationSkipReason.localOnly);
      expect(result.deleted, isTrue);
    });

    for (final status in TokenRevocationStatus.values) {
      test('revokeAndDelete deletes after ${status.name}', () async {
        store.seed(_a, 'tokenA');
        respond = (_) => _responses[status]!();
        final result = await auth.signOut(_a);
        expect(result.revocation!.status, status);
        expect(result.deleted, isTrue);
        expect(store.tokens, isEmpty);
      });

      final deletes =
          status == TokenRevocationStatus.revoked ||
          status == TokenRevocationStatus.alreadyInvalid;
      test(
        'revokeOrKeep ${deletes ? 'deletes' : 'keeps'} after ${status.name}',
        () async {
          store.seed(_a, 'tokenA');
          respond = (_) => _responses[status]!();
          final result = await auth.signOut(_a, mode: SignOutMode.revokeOrKeep);
          expect(result.revocation!.status, status);
          expect(result.deleted, deletes);
          expect(store.tokens.containsKey(_a), !deletes);
        },
      );
    }

    for (final mode in [
      SignOutMode.revokeAndDelete,
      SignOutMode.revokeOrKeep,
    ]) {
      test('${mode.name} deletes an account without a token', () async {
        store.index.add(_a);
        final result = await auth.signOut(_a, mode: mode);
        expect(requests, isEmpty);
        expect(result.skipReason, RevocationSkipReason.noStoredToken);
        expect(result.deleted, isTrue);
        expect(store.index, isEmpty);
      });

      test('${mode.name} deletes an unreadable token', () async {
        store.seed(_a, 'tokenA');
        store.throwOnRead.add(_a);
        final result = await auth.signOut(_a, mode: mode);
        expect(requests, isEmpty);
        expect(result.skipReason, RevocationSkipReason.unreadableToken);
        expect(result.deleted, isTrue);
        expect(store.tokens, isEmpty);
      });
    }

    test('throws when the local delete fails', () async {
      store.seed(_a, 'tokenA');
      store.throwOnDelete.add(_a);
      await expectLater(auth.signOut(_a), throwsA(isA<PlatformException>()));
    });

    test('clears the active account only when it is deleted', () async {
      store.seed(_a, 'tokenA');
      store.active = _a;
      respond = (_) => _responses[TokenRevocationStatus.failed]!();
      await auth.signOut(_a, mode: SignOutMode.revokeOrKeep);
      expect(store.active, _a);
      await auth.signOut(_a);
      expect(store.active, isNull);
    });

    test('keeps a token saved again while revoking', () async {
      store.seed(_a, 'tokenA');
      respond = (_) {
        // 失効を待つ間に同じアカウントで再ログインした
        store.seed(_a, 'tokenA2');
        return ResponseBody.fromString('', 204);
      };
      final result = await auth.signOut(_a);
      expect(revokedTokens(), ['tokenA']);
      expect(result.revocation!.status, TokenRevocationStatus.revoked);
      expect(result.deleted, isFalse);
      expect(store.tokens[_a]!.accessToken, 'tokenA2');
    });

    test('gives up revoking after the timeout and still deletes', () async {
      store.seed(_a, 'tokenA');
      respond = (_) => Completer<ResponseBody>().future;
      final result = await auth.signOut(
        _a,
        timeout: const Duration(milliseconds: 50),
      );
      expect(result.revocation!.status, TokenRevocationStatus.failed);
      expect(result.revocation!.error, isA<NetworkException>());
      expect(result.deleted, isTrue);
    });
  });

  group('signOutAll', () {
    void seedAll() {
      store.seed(_a, 'tokenA');
      store.seed(_b, 'tokenB');
      store.seed(_c, 'tokenC');
    }

    /// トークンごとの失効結果
    void respondBy(Map<String, TokenRevocationStatus> statuses) {
      respond = (options) => _responses[statuses[options.data['token']]]!();
    }

    test('returns results in list order', () async {
      seedAll();
      respondBy({
        'tokenA': TokenRevocationStatus.failed,
        'tokenB': TokenRevocationStatus.revoked,
        'tokenC': TokenRevocationStatus.unsupported,
      });
      final results = await auth.signOutAll();
      expect(results.map((r) => r.key), [_a, _b, _c]);
      expect(results.map((r) => r.revocation!.status), [
        TokenRevocationStatus.failed,
        TokenRevocationStatus.revoked,
        TokenRevocationStatus.unsupported,
      ]);
      expect(results.every((r) => r.deleted), isTrue);
      expect(store.tokens, isEmpty);
      expect(store.calls, isNot(contains('clearAll')));
    });

    test('revokes every account in parallel', () async {
      seedAll();
      final pending = <Completer<ResponseBody>>[];
      respond = (_) {
        final completer = Completer<ResponseBody>();
        pending.add(completer);
        return completer.future;
      };
      final future = auth.signOutAll();
      await pumpEventQueue();
      // どの応答も返る前に、すべてのリクエストが送られている
      expect(revokedTokens(), unorderedEquals(['tokenA', 'tokenB', 'tokenC']));
      for (final completer in pending) {
        completer.complete(ResponseBody.fromString('', 204));
      }
      final results = await future;
      expect(results.map((r) => r.revocation!.status).toSet(), {
        TokenRevocationStatus.revoked,
      });
    });

    test('revokeOrKeep keeps only accounts not invalidated', () async {
      seedAll();
      store.active = _c;
      respondBy({
        'tokenA': TokenRevocationStatus.alreadyInvalid,
        'tokenB': TokenRevocationStatus.failed,
        'tokenC': TokenRevocationStatus.unsupported,
      });
      final results = await auth.signOutAll(mode: SignOutMode.revokeOrKeep);
      expect(results.map((r) => r.deleted), [true, false, false]);
      expect(store.index, [_b, _c]);
      expect(store.active, _c);
    });

    test('applies one deadline to the whole operation', () async {
      seedAll();
      respond = (options) => options.uri.host == 'c.test'
          ? Completer<ResponseBody>().future
          : ResponseBody.fromString('', 204);
      final stopwatch = Stopwatch()..start();
      final results = await auth.signOutAll(
        timeout: const Duration(milliseconds: 100),
      );
      expect(stopwatch.elapsed, lessThan(const Duration(seconds: 5)));
      expect(results.map((r) => r.revocation!.status), [
        TokenRevocationStatus.revoked,
        TokenRevocationStatus.revoked,
        TokenRevocationStatus.failed,
      ]);
      expect(results.every((r) => r.deleted), isTrue);
    });

    test('counts the deadline from the call, including list', () async {
      seedAll();
      store.beforeList = () =>
          Future<void>.delayed(const Duration(milliseconds: 150));
      final results = await auth.signOutAll(
        timeout: const Duration(milliseconds: 100),
      );
      // 一覧を読む間に期限が過ぎたため、失効は送らない
      expect(requests, isEmpty);
      expect(results.map((r) => r.revocation!.status).toSet(), {
        TokenRevocationStatus.failed,
      });
      expect(results.every((r) => r.deleted), isTrue);
    });

    test('localOnly clears the store without reading or revoking', () async {
      seedAll();
      final results = await auth.signOutAll(mode: SignOutMode.localOnly);
      expect(requests, isEmpty);
      expect(store.calls, ['list', 'clearAll']);
      expect(results.map((r) => r.key), [_a, _b, _c]);
      expect(results.map((r) => r.skipReason).toSet(), {
        RevocationSkipReason.localOnly,
      });
    });

    test('deletes an unreadable token and revokes the others', () async {
      seedAll();
      store.throwOnRead.add(_b);
      final results = await auth.signOutAll();
      expect(revokedTokens(), unorderedEquals(['tokenA', 'tokenC']));
      expect(results[1].skipReason, RevocationSkipReason.unreadableToken);
      expect(results.every((r) => r.deleted), isTrue);
      expect(store.index, isEmpty);
    });

    test('propagates a failure to list the accounts', () async {
      store.throwOnList = true;
      await expectLater(auth.signOutAll(), throwsA(isA<PlatformException>()));
      expect(requests, isEmpty);
    });

    test('tries every delete before throwing the first error', () async {
      seedAll();
      store.throwOnDelete.addAll([_a, _b]);
      await expectLater(auth.signOutAll(), throwsA(isA<PlatformException>()));
      expect(store.calls.where((c) => c.startsWith('delete')), [
        'delete:userA',
        'delete:userB',
        'delete:userC',
      ]);
      expect(store.index, [_a, _b]);
    });

    test('keeps an account added while revoking', () async {
      store.seed(_a, 'tokenA');
      const added = AccountKey(host: 'a.test', accountId: 'added');
      respond = (_) {
        store.seed(added, 'tokenAdded');
        return ResponseBody.fromString('', 204);
      };
      final results = await auth.signOutAll();
      expect(results.map((r) => r.key), [_a]);
      expect(store.index, [added]);
    });
  });

  test('uses an injected revocation client', () async {
    final other = <RequestOptions>[];
    final otherDio = Dio()
      ..httpClientAdapter = StubAdapter((options) {
        other.add(options);
        return ResponseBody.fromString('', 204);
      });
    addTearDown(() => otherDio.close(force: true));
    final manager = MisskeyAuthManager(
      miauth: MisskeyMiAuthClient(),
      oauth: MisskeyOAuthClient(),
      store: store,
      dio: dio,
      revocation: MisskeyTokenRevocationClient(dio: otherDio),
    );
    store.seed(_a, 'tokenA');
    await manager.signOut(_a);
    expect(requests, isEmpty);
    expect(other, hasLength(1));
  });
}
