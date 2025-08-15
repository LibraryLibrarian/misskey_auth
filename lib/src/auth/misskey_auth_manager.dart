import 'package:dio/dio.dart';

import '../api/misskey_miauth_client.dart';
import '../api/misskey_oauth_client.dart';
import '../exceptions/misskey_auth_exception.dart';
import '../models/miauth_models.dart';
import '../models/oauth_models.dart';
import '../store/account_key.dart';
import '../store/secure_token_store.dart';
import '../store/stored_token.dart';
import '../store/token_store.dart';

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

  MisskeyAuthManager({
    required this.miauth,
    required this.oauth,
    required this.store,
    Dio? dio,
    Duration? connectTimeout,
    Duration? sendTimeout,
    Duration? receiveTimeout,
  }) : dio = dio ??
            Dio(BaseOptions(
              connectTimeout: connectTimeout ?? const Duration(seconds: 10),
              sendTimeout: sendTimeout ?? const Duration(seconds: 20),
              receiveTimeout: receiveTimeout ?? const Duration(seconds: 20),
            ));

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
      String host, String accessToken) async {
    try {
      final url = 'https://$host/api/i';
      final response = await dio.post(
        url,
        // Misskeyの一般的な仕様に従い、リクエストボディに `i` でトークンを渡す
        data: <String, dynamic>{'i': accessToken},
      );
      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }
      throw ResponseParseException(details: 'Unexpected /api/i response');
    } on DioException catch (e) {
      throw NetworkException(details: e.message, originalException: e);
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

  /// 指定アカウントのトークンを削除（サインアウト相当）
  Future<void> signOut(AccountKey key) => store.delete(key);

  /// すべてのトークンを削除（全サインアウト）
  Future<void> signOutAll() => store.clearAll();
}
