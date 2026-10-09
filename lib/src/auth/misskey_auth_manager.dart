import 'package:dio/dio.dart';

import '../api/misskey_miauth_client.dart';
import '../api/misskey_oauth_client.dart';
import '../api/misskey_token_revocation_client.dart';
import '../exceptions/misskey_auth_exception.dart';
import '../models/miauth_models.dart';
import '../models/oauth_models.dart';
import '../models/sign_out_models.dart';
import '../models/token_revocation_models.dart';
import '../store/account_key.dart';
import '../store/secure_token_store.dart';
import '../store/stored_token.dart';
import '../store/token_store.dart';
import '../net/response.dart';
import '../net/retry.dart';

/// Misskey 認証の高レベル管理クラス
///
/// - 認証（MiAuth/OAuth）の実行と、`TokenStore` への保存を仲介
/// - OAuth 認証後は `/api/i` を呼び出し、`accountId` を自動解決
/// - アクティブアカウントの設定/取得、トークン取得、サインアウト等を提供
class MisskeyAuthManager {
  final MisskeyMiAuthClient miauth;
  final MisskeyOAuthClient oauth;
  final TokenStore store;
  final Dio dio;

  /// サインアウト時にサーバー上のトークンを失効させるクライアント
  final MisskeyTokenRevocationClient revocation;

  /// [revocation] を渡さない場合は、[dio] を使う失効クライアントを組み立てる。
  /// タイムアウトの引数は、[dio] を渡さない場合に `/api/i` と失効の通信に適用する
  MisskeyAuthManager({
    required MisskeyMiAuthClient miauth,
    required MisskeyOAuthClient oauth,
    required TokenStore store,
    MisskeyTokenRevocationClient? revocation,
    Dio? dio,
    Duration? connectTimeout,
    Duration? sendTimeout,
    Duration? receiveTimeout,
  }) : this._(
         miauth,
         oauth,
         store,
         revocation,
         dio ??
             Dio(
               BaseOptions(
                 connectTimeout: connectTimeout ?? const Duration(seconds: 10),
                 sendTimeout: sendTimeout ?? const Duration(seconds: 20),
                 receiveTimeout: receiveTimeout ?? const Duration(seconds: 20),
               ),
             ),
       );

  MisskeyAuthManager._(
    this.miauth,
    this.oauth,
    this.store,
    MisskeyTokenRevocationClient? revocation,
    this.dio,
  ) : revocation = revocation ?? MisskeyTokenRevocationClient(dio: dio);

  /// 依存を既定実装で組み立てたインスタンスを返す
  factory MisskeyAuthManager.defaultInstance() => MisskeyAuthManager(
    miauth: MisskeyMiAuthClient(),
    oauth: MisskeyOAuthClient(),
    store: const SecureTokenStore(),
  );

  /// MiAuth で認証を実行し、トークンを保存
  ///
  /// 認証後、ユーザー情報に含まれる `user.id` を `accountId` に採用
  Future<AccountKey> loginWithMiAuth(
    MisskeyMiAuthConfig config, {
    bool setActive = true,
  }) async {
    final res = await miauth.authenticate(config);
    // MiAuth は user 情報がレスポンスに含まれる
    final user = res.user ?? <String, dynamic>{};
    final accountId = _resolveAccountIdFromUser(user);
    final key = AccountKey(host: config.host, accountId: accountId);
    final token = StoredToken(
      accessToken: res.token,
      tokenType: 'MiAuth',
      user: user,
      createdAt: DateTime.now(),
    );
    await store.upsert(key, token);
    if (setActive) {
      await store.setActive(key);
    }
    return key;
  }

  /// OAuth で認証を実行し、トークンを保存
  ///
  /// 認証後に `/api/i` を呼び出して `accountId` を解決
  Future<AccountKey> loginWithOAuth(
    MisskeyOAuthConfig config, {
    bool setActive = true,
  }) async {
    final tokenRes = await oauth.authenticate(config);
    if (tokenRes == null) {
      throw const MisskeyAuthException('OAuth認証が完了しませんでした');
    }
    // 認可直後に /api/i で accountId を解決
    final user = await _fetchCurrentUser(config.host, tokenRes.accessToken);
    final accountId = _resolveAccountIdFromUser(user);
    final key = AccountKey(host: config.host, accountId: accountId);
    final token = StoredToken(
      accessToken: tokenRes.accessToken,
      tokenType: 'OAuth',
      scope: tokenRes.scope,
      user: user,
      createdAt: DateTime.now(),
    );
    await store.upsert(key, token);
    if (setActive) {
      await store.setActive(key);
    }
    return key;
  }

  /// `/api/i` を呼び出し、現在のユーザー情報を取得
  Future<Map<String, dynamic>> _fetchCurrentUser(
    String host,
    String accessToken,
  ) async {
    try {
      final url = 'https://$host/api/i';
      final response = await retry(
        () => dio.post(
          url,
          // Misskeyの一般的な仕様に従い、リクエストボディに `i` でトークンを渡す
          data: <String, dynamic>{'i': accessToken},
        ),
        const RetryPolicy(maxAttempts: 3),
      );
      if (response.statusCode == 200) {
        return jsonObjectOf(response.data);
      }
      throw ResponseParseException(
        details: 'Unexpected /api/i response: ${response.statusCode}',
      );
    } on DioException catch (e) {
      throw transportExceptionOf(e);
    } on FormatException catch (e) {
      throw ResponseParseException(details: e.message, originalException: e);
    }
  }

  /// ユーザー情報から `accountId` を解決
  String _resolveAccountIdFromUser(Map<String, dynamic> user) {
    final id = user['id'];
    if (id is String && id.isNotEmpty) return id;
    throw ResponseParseException(details: 'User id not found');
  }

  /// アクティブアカウントの `StoredToken` を取得。未設定時は `null`
  Future<StoredToken?> currentToken() async {
    final active = await store.getActive();
    if (active == null) return null;
    return store.read(active);
  }

  /// 指定アカウントの `StoredToken` を取得。未保存時は `null`
  Future<StoredToken?> tokenOf(AccountKey key) => store.read(key);

  /// アクティブアカウントを設定する
  Future<void> setActive(AccountKey key) => store.setActive(key);

  /// 現在のアクティブアカウントを取得
  Future<AccountKey?> getActive() => store.getActive();

  /// アクティブアカウント設定を解除
  Future<void> clearActive() => store.setActive(null);

  /// 保存済みアカウントの一覧を取得
  Future<List<AccountEntry>> listAccounts() => store.list();

  /// 指定アカウントをサインアウトする
  ///
  /// 既定（[SignOutMode.revokeAndDelete]）では、サーバー上のトークンの失効を
  /// 試みてから、結果にかかわらず端末上のトークンを削除する。失効の結果は
  /// 例外ではなく [SignOutResult.revocation] で返す。保存されたトークンが
  /// 無い、または読み出せない場合は、失効を試みずに削除する。
  ///
  /// [timeout] は失効のリクエスト全体の期限。省略時は通信のタイムアウトに従う。
  /// 端末上の削除に失敗した場合は、ストレージの例外をそのまま投げる
  Future<SignOutResult> signOut(
    AccountKey key, {
    SignOutMode mode = SignOutMode.revokeAndDelete,
    Duration? timeout,
  }) async {
    if (mode == SignOutMode.localOnly) {
      await store.delete(key);
      return SignOutResult(
        key: key,
        skipReason: RevocationSkipReason.localOnly,
        deleted: true,
      );
    }
    final attempt = await _revokeStored(key, _remainingOf(timeout));
    return _deleteAfter(attempt, mode);
  }

  /// 保存済みのすべてのアカウントをサインアウトする
  ///
  /// 各アカウントの扱いは [signOut] と同じ。失効は全アカウントで並列に試み、
  /// [timeout] は呼び出しの時点から数えた、すべての失効に共通の期限として扱う
  /// （端末上の読み書きは打ち切らない）。結果は [listAccounts] の順に返す。
  /// 端末上の削除はすべて試み、失敗したものがあれば最初の例外を最後に投げる
  Future<List<SignOutResult>> signOutAll({
    SignOutMode mode = SignOutMode.revokeAndDelete,
    Duration? timeout,
  }) async {
    // 期限はアカウント一覧の読み出しも含め、呼び出しの時点から数える
    final remaining = _remainingOf(timeout);
    final entries = await store.list();
    if (mode == SignOutMode.localOnly) {
      await store.clearAll();
      return [
        for (final entry in entries)
          SignOutResult(
            key: entry.key,
            skipReason: RevocationSkipReason.localOnly,
            deleted: true,
          ),
      ];
    }
    final attempts = await Future.wait([
      for (final entry in entries) _revokeStored(entry.key, remaining),
    ]);
    // 失効を待つ間に追加されたアカウントを消さないよう、clearAll は使わない
    final results = <SignOutResult>[];
    Object? firstError;
    StackTrace? firstStackTrace;
    for (final attempt in attempts) {
      try {
        results.add(await _deleteAfter(attempt, mode));
      } catch (e, st) {
        firstError ??= e;
        firstStackTrace ??= st;
      }
    }
    if (firstError != null) {
      Error.throwWithStackTrace(firstError, firstStackTrace!);
    }
    return results;
  }

  /// [timeout] を起点からの期限とみなし、呼ぶたびに残り時間を返す関数を作る
  Duration? Function() _remainingOf(Duration? timeout) {
    if (timeout == null) return () => null;
    final stopwatch = Stopwatch()..start();
    return () => timeout - stopwatch.elapsed;
  }

  /// 保存されたトークンを読み出し、サーバー上で失効を試みる
  Future<_RevocationAttempt> _revokeStored(
    AccountKey key,
    Duration? Function() remaining,
  ) async {
    final StoredToken? token;
    try {
      token = await store.read(key);
    } catch (_) {
      return _RevocationAttempt.skipped(
        key,
        RevocationSkipReason.unreadableToken,
      );
    }
    if (token == null) {
      return _RevocationAttempt.skipped(
        key,
        RevocationSkipReason.noStoredToken,
      );
    }
    final result = await revocation.revoke(
      host: key.host,
      accessToken: token.accessToken,
      timeout: remaining(),
    );
    return _RevocationAttempt(key, token.accessToken, result);
  }

  /// 失効の結果と [mode] に従って、端末上のトークンを削除する
  Future<SignOutResult> _deleteAfter(
    _RevocationAttempt attempt,
    SignOutMode mode,
  ) async {
    final key = attempt.key;
    final result = attempt.result;
    if (result == null) {
      await store.delete(key);
      return SignOutResult(
        key: key,
        skipReason: attempt.skipReason,
        deleted: true,
      );
    }
    final keep =
        (mode == SignOutMode.revokeOrKeep && !result.isInvalidated) ||
        await _replacedSince(key, attempt.accessToken!);
    if (!keep) await store.delete(key);
    return SignOutResult(key: key, revocation: result, deleted: !keep);
  }

  /// 失効を待つ間に、同じアカウントへ別のトークンが保存されたか
  ///
  /// 再ログインで保存されたトークンを、失効させないまま削除しないために確認する
  Future<bool> _replacedSince(AccountKey key, String accessToken) async {
    try {
      final current = await store.read(key);
      return current != null && current.accessToken != accessToken;
    } catch (_) {
      return false;
    }
  }
}

/// 1アカウント分の失効の試行結果
class _RevocationAttempt {
  final AccountKey key;

  /// 失効を試みたトークン。試みなかった場合は `null`
  final String? accessToken;
  final TokenRevocationResult? result;
  final RevocationSkipReason? skipReason;

  const _RevocationAttempt(this.key, this.accessToken, this.result)
    : skipReason = null;

  const _RevocationAttempt.skipped(this.key, this.skipReason)
    : accessToken = null,
      result = null;
}
