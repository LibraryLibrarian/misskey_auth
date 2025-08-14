import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import '../models/oauth_models.dart';
import '../exceptions/misskey_auth_exception.dart';

/// MisskeyのOAuth認証を管理するクライアント
class MisskeyOAuthClient {
  final Dio _dio;
  final FlutterSecureStorage _storage;

  // ストレージキー
  static const _accessTokenKey = 'misskey_access_token';
  static const _refreshTokenKey = 'misskey_refresh_token';
  static const _expiresAtKey = 'misskey_expires_at';
  static const _hostKey = 'misskey_host';

  MisskeyOAuthClient({
    Dio? dio,
    FlutterSecureStorage? storage,
  })  : _dio = dio ?? Dio(),
        _storage = storage ?? const FlutterSecureStorage();

  /// OAuth認証サーバー情報を取得
  Future<OAuthServerInfo?> getOAuthServerInfo(String host) async {
    try {
      final response = await _dio.get(
        'https://$host/.well-known/oauth-authorization-server',
      );

      if (response.statusCode == 200) {
        return OAuthServerInfo.fromJson(response.data);
      }
      if (response.statusCode == 404 || response.statusCode == 501) {
        // 非対応と判断
        return null;
      }
      // その他のステータスはサーバー側の問題として扱う
      throw ServerInfoException('OAuth情報の取得に失敗しました: ${response.statusCode}');
    } on DioException catch (e) {
      if (e.response?.statusCode == 404 || e.response?.statusCode == 501) {
        return null; // 非対応
      }
      throw NetworkException(details: e.message, originalException: e);
    } on FormatException catch (e) {
      throw ResponseParseException(details: e.message, originalException: e);
    } catch (e) {
      if (kDebugMode) {
        print('OAuth情報取得エラー: $e');
      }
      throw ServerInfoException('OAuth情報の取得に失敗しました: $e');
    }
  }

  /// PKCE用のコードベリファイアを生成
  String generateCodeVerifier() {
    const charset =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
    final random = Random.secure();
    return List.generate(128, (_) => charset[random.nextInt(charset.length)])
        .join();
  }

  /// コードチャレンジを生成
  String generateCodeChallenge(String codeVerifier) {
    final bytes = utf8.encode(codeVerifier);
    final digest = sha256.convert(bytes);
    return base64UrlEncode(digest.bytes).replaceAll('=', '');
  }

  /// ランダムなstateを生成
  String generateState() {
    final random = Random.secure();
    return base64UrlEncode(List<int>.generate(32, (_) => random.nextInt(256)))
        .replaceAll('=', '');
  }

  /// OAuth認証を開始
  Future<OAuthTokenResponse?> authenticate(MisskeyOAuthConfig config) async {
    try {
      // 1. OAuth情報を取得
      if (kDebugMode) {
        print('OAuth情報を取得中: ${config.host}');
      }
      final serverInfo = await getOAuthServerInfo(config.host);
      if (serverInfo == null) {
        throw OAuthNotSupportedException(config.host);
      }
      if (kDebugMode) {
        print('認証エンドポイント: ${serverInfo.authorizationEndpoint}');
        print('トークンエンドポイント: ${serverInfo.tokenEndpoint}');
      }

      // 2. PKCE準備
      final codeVerifier = generateCodeVerifier();
      final codeChallenge = generateCodeChallenge(codeVerifier);
      final state = generateState();

      if (kDebugMode) {
        print('PKCE準備完了');
        print('code_challenge: $codeChallenge');
        print('state: $state');
      }

      // 3. 認証URLを構築
      final authUrl = Uri.parse(serverInfo.authorizationEndpoint).replace(
        queryParameters: {
          'client_id': config.clientId,
          'response_type': 'code',
          'redirect_uri': config.redirectUri,
          'scope': config.scope,
          'code_challenge': codeChallenge,
          'code_challenge_method': 'S256',
          'state': state,
        },
      );

      if (kDebugMode) {
        print('認証URL: $authUrl');
      }

      // 4. flutter_web_auth_2で認証ページを開く
      // カスタムスキーム
      final redirectUriScheme =
          Uri.parse(config.redirectUri).scheme.toLowerCase();
      final callbackUrlScheme =
          (redirectUriScheme != 'http' && redirectUriScheme != 'https')
              ? redirectUriScheme
              : config.callbackScheme;
      if (kDebugMode) {
        print('コールバックURLスキーム: $callbackUrlScheme');
      }

      late final String result;
      try {
        result = await FlutterWebAuth2.authenticate(
          url: authUrl.toString(),
          callbackUrlScheme: callbackUrlScheme,
        );
      } on PlatformException catch (e) {
        // FlutterWebAuth2 の代表的なケースをマッピング
        final code = (e.code).toLowerCase();
        if (code.contains('cancel')) {
          throw const UserCancelledException();
        }
        // コールバックスキーム不一致/未設定の可能性
        if (e.message != null &&
            e.message!.toLowerCase().contains('callback')) {
          throw CallbackSchemeErrorException(
              details: e.message, originalException: e);
        }
        throw AuthorizationLaunchException(
            details: e.message, originalException: e);
      } catch (e) {
        if (e is MisskeyAuthException) rethrow;
        throw AuthorizationLaunchException(details: e.toString());
      }

      if (kDebugMode) {
        print('認証結果URL: $result');
      }

      // 5. コールバックURLからパラメータを取得
      final uri = Uri.parse(result);
      // 認可サーバーからのエラー（RFC6749）
      final authError = uri.queryParameters['error'];
      if (authError != null && authError.isNotEmpty) {
        final desc = uri.queryParameters['error_description'];
        final errMsg = desc == null || desc.isEmpty
            ? 'error=$authError'
            : 'error=$authError, description=$desc';
        throw AuthorizationServerErrorException(details: errMsg);
      }

      final code = uri.queryParameters['code'];
      final returnedState = uri.queryParameters['state'];

      if (kDebugMode) {
        print('認証コード: ${code?.substring(0, 10)}...');
        print('返却されたstate: $returnedState');
      }

      // 6. stateを検証
      if (returnedState != state) {
        throw const StateMismatchException();
      }

      if (code == null) {
        throw const AuthorizationCodeMissingException();
      }

      // 7. 認証コードをトークンと交換
      if (kDebugMode) {
        print('トークン交換中...');
      }
      final tokenResponse = await exchangeCodeForToken(
        tokenEndpoint: serverInfo.tokenEndpoint,
        clientId: config.clientId,
        redirectUri: config.redirectUri,
        scope: config.scope,
        code: code,
        codeVerifier: codeVerifier,
      );

      // 8. トークンを保存
      try {
        await _saveTokens(
          host: config.host,
          accessToken: tokenResponse.accessToken,
          refreshToken: tokenResponse.refreshToken,
          expiresIn: tokenResponse.expiresIn,
        );
      } on PlatformException catch (e) {
        throw SecureStorageException(details: e.message, originalException: e);
      } catch (e) {
        if (e is MisskeyAuthException) rethrow;
        throw SecureStorageException(details: e.toString());
      }

      if (kDebugMode) {
        print('認証成功！');
      }
      return tokenResponse;
    } on MisskeyAuthException {
      rethrow;
    } on DioException catch (e) {
      // ネットワーク層の例外
      throw NetworkException(details: e.message, originalException: e);
    } on PlatformException catch (e) {
      final code = (e.code).toLowerCase();
      if (code.contains('cancel')) {
        throw const UserCancelledException();
      }
      throw AuthorizationLaunchException(
          details: e.message, originalException: e);
    } catch (e) {
      if (kDebugMode) {
        print('認証エラー: $e');
      }
      // 想定外はベース例外に包む
      throw MisskeyAuthException(e.toString());
    }
  }

  /// アクセストークンを取得
  Future<OAuthTokenResponse> exchangeCodeForToken({
    required String tokenEndpoint,
    required String clientId,
    required String redirectUri,
    required String scope,
    required String code,
    required String codeVerifier,
  }) async {
    try {
      final response = await _dio.post(
        tokenEndpoint,
        options: Options(
          contentType: 'application/x-www-form-urlencoded',
        ),
        data: {
          'grant_type': 'authorization_code',
          'client_id': clientId,
          'redirect_uri': redirectUri,
          'scope': scope,
          'code': code,
          'code_verifier': codeVerifier,
        },
      );

      if (response.statusCode == 200) {
        return OAuthTokenResponse.fromJson(response.data);
      }
      final status = response.statusCode;
      String message = 'トークン交換に失敗しました: $status';
      // RFC準拠のエラーフィールドがあれば詳細に含める
      final data = response.data;
      if (data is Map<String, dynamic>) {
        final err = data['error'];
        final desc = data['error_description'];
        if (err != null) {
          message =
              '$message (error=$err${desc != null ? ', description=$desc' : ''})';
        }
      }
      throw TokenExchangeException(message);
    } on DioException catch (e) {
      if (kDebugMode) {
        print('DioException: ${e.response?.data}');
      }
      if (e.response != null) {
        final status = e.response?.statusCode;
        String message = 'トークン交換に失敗しました: $status';
        final data = e.response?.data;
        if (data is Map<String, dynamic>) {
          final err = data['error'];
          final desc = data['error_description'];
          if (err != null) {
            message =
                '$message (error=$err${desc != null ? ', description=$desc' : ''})';
          }
        }
        throw TokenExchangeException(message);
      }
      // レスポンスが無い＝ネットワーク層の失敗
      throw NetworkException(details: e.message, originalException: e);
    } on FormatException catch (e) {
      throw ResponseParseException(details: e.message, originalException: e);
    } catch (e) {
      throw MisskeyAuthException('トークン交換中にエラーが発生しました', details: e.toString());
    }
  }

  /// トークンを保存
  Future<void> _saveTokens({
    required String host,
    required String accessToken,
    String? refreshToken,
    int? expiresIn,
  }) async {
    await _storage.write(key: _hostKey, value: host);
    await _storage.write(key: _accessTokenKey, value: accessToken);

    if (refreshToken != null) {
      await _storage.write(key: _refreshTokenKey, value: refreshToken);
    }

    if (expiresIn != null) {
      final expiresAt = DateTime.now().add(Duration(seconds: expiresIn));
      await _storage.write(
          key: _expiresAtKey, value: expiresAt.toIso8601String());
    }
  }

  /// 保存されたアクセストークンを取得
  Future<String?> getStoredAccessToken() async {
    try {
      return await _storage.read(key: _accessTokenKey);
    } on PlatformException catch (e) {
      throw SecureStorageException(details: e.message, originalException: e);
    }
  }

  /// トークンをクリア
  Future<void> clearTokens() async {
    try {
      await _storage.deleteAll();
    } on PlatformException catch (e) {
      throw SecureStorageException(details: e.message, originalException: e);
    }
  }
}
