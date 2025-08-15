import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import '../models/oauth_models.dart';
import '../exceptions/misskey_auth_exception.dart';

/// MisskeyのOAuth認証を管理するクライアント
class MisskeyOAuthClient {
  final Dio _dio;
  // 保存責務は削除（TokenStore が担当）

  /// 認証通信で使用するHTTPクライアント
  ///
  /// [dio] を渡さない場合は、次のデフォルトタイムアウトで初期化：
  /// - 接続: 10秒
  /// - 送信:  20秒
  /// - 受信:  20秒
  /// これらは [connectTimeout]/[sendTimeout]/[receiveTimeout] で上書き可能
  MisskeyOAuthClient({
    Dio? dio,
    Duration? connectTimeout,
    Duration? sendTimeout,
    Duration? receiveTimeout,
  }) : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: connectTimeout ?? const Duration(seconds: 10),
              sendTimeout: sendTimeout ?? const Duration(seconds: 20),
              receiveTimeout: receiveTimeout ?? const Duration(seconds: 20),
            )) {
    if (dio != null) {
      if (connectTimeout != null) _dio.options.connectTimeout = connectTimeout;
      if (sendTimeout != null) _dio.options.sendTimeout = sendTimeout;
      if (receiveTimeout != null) _dio.options.receiveTimeout = receiveTimeout;
    }
  }

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

      // 8. 成功（保存は呼び出し側で TokenStore が担当）
      if (kDebugMode) print('認証成功！');
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

  // 保存・読み出し・クリアの責務は廃止
}
