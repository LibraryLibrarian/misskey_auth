import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';

import '../models/oauth_models.dart';
import '../exceptions/misskey_auth_exception.dart';
import '../net/response.dart';
import '../net/retry.dart';

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
  }) : _dio =
           dio ??
           Dio(
             BaseOptions(
               connectTimeout: connectTimeout ?? const Duration(seconds: 10),
               sendTimeout: sendTimeout ?? const Duration(seconds: 20),
               receiveTimeout: receiveTimeout ?? const Duration(seconds: 20),
             ),
           ) {
    if (dio != null) {
      if (connectTimeout != null) _dio.options.connectTimeout = connectTimeout;
      if (sendTimeout != null) _dio.options.sendTimeout = sendTimeout;
      if (receiveTimeout != null) _dio.options.receiveTimeout = receiveTimeout;
    }
  }

  /// OAuth認証サーバー情報を取得
  ///
  /// サーバーが OAuth に対応していない（404/501）場合は `null`。
  /// RFC 8414 に従い、`issuer` が `https://{host}` と完全一致しない場合や、
  /// エンドポイントが HTTPS の絶対 URL でない場合は [ServerInfoException]
  Future<OAuthServerInfo?> getOAuthServerInfo(String host) async {
    try {
      final origin = Uri.parse('https://${host.trim()}').origin;
      final response = await retry(
        () => _dio.get('$origin/.well-known/oauth-authorization-server'),
        const RetryPolicy(maxAttempts: 3),
      );

      if (response.statusCode == 200) {
        final json = jsonObjectOf(response.data);
        final info = OAuthServerInfo.fromJson(json);
        _verifyServerInfo(json['issuer'], info, expectedIssuer: origin);
        return info;
      }
      if (response.statusCode == 404 || response.statusCode == 501) {
        // 非対応と判断
        return null;
      }
      // その他のステータスはサーバー側の問題として扱う
      throw ServerInfoException('OAuth情報の取得に失敗しました: ${response.statusCode}');
    } on MisskeyAuthException {
      rethrow;
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 404 || status == 501) {
        return null; // 非対応
      }
      if (e.type == DioExceptionType.badResponse) {
        throw ServerInfoException('OAuth情報の取得に失敗しました: $status');
      }
      throw transportExceptionOf(e);
    } on FormatException catch (e) {
      throw ResponseParseException(details: e.message, originalException: e);
    } catch (e) {
      throw ServerInfoException('OAuth情報の取得に失敗しました: $e');
    }
  }

  /// discovery の内容が接続先サーバーのものとして妥当かを確認
  void _verifyServerInfo(
    Object? issuer,
    OAuthServerInfo info, {
    required String expectedIssuer,
  }) {
    // 受信値は正規化せず完全一致で比較する（RFC 8414 §3.3）。
    // 受信値は資格情報を含み得るため、例外には載せない
    if (issuer != expectedIssuer) {
      throw ServerInfoException(
        'OAuth情報の issuer が接続先と一致しません: expected=$expectedIssuer',
      );
    }
    _requireSecureEndpoint(
      'authorization_endpoint',
      info.authorizationEndpoint,
    );
    _requireSecureEndpoint('token_endpoint', info.tokenEndpoint);
  }

  /// エンドポイントが HTTPS の絶対 URL であることを確認
  void _requireSecureEndpoint(String name, String value) {
    final uri = Uri.tryParse(value);
    final isSecure =
        uri != null &&
        uri.isScheme('https') &&
        uri.host.isNotEmpty &&
        uri.userInfo.isEmpty &&
        !uri.hasFragment;
    if (!isSecure) {
      throw ServerInfoException('OAuth情報の $name が HTTPS の絶対 URL ではありません');
    }
  }

  /// PKCE用のコードベリファイアを生成
  String generateCodeVerifier() {
    const charset =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
    final random = Random.secure();
    return List.generate(
      128,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
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
  ///
  /// 認可コードの交換に失敗した場合は、ブラウザでの認可からやり直す必要がある
  /// （[exchangeCodeForToken] 参照）
  Future<OAuthTokenResponse?> authenticate(MisskeyOAuthConfig config) async {
    try {
      // 1. OAuth情報を取得
      final serverInfo = await getOAuthServerInfo(config.host);
      if (serverInfo == null) {
        throw OAuthNotSupportedException(config.host);
      }

      // 2. PKCE準備
      final codeVerifier = generateCodeVerifier();
      final codeChallenge = generateCodeChallenge(codeVerifier);
      final state = generateState();

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

      // 4. flutter_web_auth_2で認証ページを開く
      // カスタムスキーム
      final redirectUriScheme = Uri.parse(config.redirectUri).scheme
          .toLowerCase();
      final callbackUrlScheme =
          (redirectUriScheme != 'http' && redirectUriScheme != 'https')
          ? redirectUriScheme
          : config.callbackScheme;

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
            details: e.message,
            originalException: e,
          );
        }
        throw AuthorizationLaunchException(
          details: e.message,
          originalException: e,
        );
      } catch (e) {
        if (e is MisskeyAuthException) rethrow;
        throw AuthorizationLaunchException(details: e.toString());
      }

      // 5. stateを検証
      // エラー応答にも state は付くため、error の解釈より先に照合する
      final params = Uri.tryParse(result)?.queryParametersAll ?? const {};
      final returnedStates = params['state'];
      if (returnedStates == null ||
          returnedStates.length != 1 ||
          returnedStates.single != state) {
        throw const StateMismatchException();
      }

      // 6. 認可サーバーからのエラー（RFC6749）
      final authError = params['error']?.first;
      if (authError != null && authError.isNotEmpty) {
        final desc = params['error_description']?.first;
        final errMsg = desc == null || desc.isEmpty
            ? 'error=$authError'
            : 'error=$authError, description=$desc';
        throw AuthorizationServerErrorException(details: errMsg);
      }

      final codes = params['code'];
      if (codes != null && codes.length > 1) {
        throw const AuthorizationCodeMissingException(
          details: 'The callback contains multiple codes.',
        );
      }
      final code = codes?.single;
      if (code == null || code.isEmpty) {
        throw const AuthorizationCodeMissingException();
      }

      // 7. 認証コードをトークンと交換
      final tokenResponse = await exchangeCodeForToken(
        tokenEndpoint: serverInfo.tokenEndpoint,
        clientId: config.clientId,
        redirectUri: config.redirectUri,
        scope: config.scope,
        code: code,
        codeVerifier: codeVerifier,
      );

      // 8. 成功（保存は呼び出し側で TokenStore が担当）
      return tokenResponse;
    } on MisskeyAuthException {
      rethrow;
    } on DioException catch (e) {
      throw transportExceptionOf(e);
    } on PlatformException catch (e) {
      final code = (e.code).toLowerCase();
      if (code.contains('cancel')) {
        throw const UserCancelledException();
      }
      throw AuthorizationLaunchException(
        details: e.message,
        originalException: e,
      );
    } catch (e) {
      // 想定外はベース例外に包む
      throw MisskeyAuthException(e.toString());
    }
  }

  /// アクセストークンを取得
  ///
  /// 認可コードは一度しか使えないため、失敗しても自動で再送しない。
  /// 通信が途中で失敗した場合、サーバー側では交換が済んでいる可能性があり、
  /// 同じコードでは再試行できない。[authenticate] からやり直すこと
  Future<OAuthTokenResponse> exchangeCodeForToken({
    required String tokenEndpoint,
    required String clientId,
    required String redirectUri,
    required String scope,
    required String code,
    required String codeVerifier,
  }) async {
    try {
      // 認可コードは一度しか使えない。サーバー側で交換済みの可能性があるため再送しない
      final response = await _dio.post(
        tokenEndpoint,
        options: Options(contentType: 'application/x-www-form-urlencoded'),
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
        return OAuthTokenResponse.fromJson(jsonObjectOf(response.data));
      }
      throw _tokenExchangeError(response.statusCode, response.data);
    } on MisskeyAuthException {
      rethrow;
    } on DioException catch (e) {
      final response = e.response;
      if (e.type == DioExceptionType.badResponse && response != null) {
        throw _tokenExchangeError(response.statusCode, response.data);
      }
      throw transportExceptionOf(e);
    } on FormatException catch (e) {
      throw ResponseParseException(details: e.message, originalException: e);
    } catch (e) {
      throw MisskeyAuthException('トークン交換中にエラーが発生しました', details: e.toString());
    }
  }

  /// トークンエンドポイントのエラー応答を例外に変換
  TokenExchangeException _tokenExchangeError(int? status, Object? data) {
    final summary = errorSummaryOf(data);
    final message = 'トークン交換に失敗しました: $status';
    return TokenExchangeException(
      summary == null ? message : '$message ($summary)',
    );
  }

  // 保存・読み出し・クリアの責務は廃止
}
