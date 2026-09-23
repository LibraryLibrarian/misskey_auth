import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';

import '../models/miauth_models.dart';
import '../exceptions/misskey_auth_exception.dart';
import '../net/response.dart';
import '../net/retry.dart';

/// Misskey の MiAuth 認証を扱うクライアント
class MisskeyMiAuthClient {
  final Dio _dio;

  /// 認証通信で使用するHTTPクライアント
  ///
  /// [dio] を渡さない場合は、次のデフォルトタイムアウトで初期化
  /// - 接続: 10秒
  /// - 送信:  20秒
  /// - 受信:  20秒
  MisskeyMiAuthClient({
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

  /// ランダムなセッション ID を生成（URL セーフな英数字）
  String generateSessionId({int length = 32}) {
    const charset =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  /// MiAuth 認証を開始し、成功すればアクセストークンを返す
  Future<MiAuthTokenResponse> authenticate(MisskeyMiAuthConfig config) async {
    try {
      // 1. セッション ID を生成
      final sessionId = generateSessionId();

      // 2. 認証 URL を構築
      final permissions = config.permissions.join(',');
      final query = <String, String>{
        'name': config.appName,
        'callback': config.callbackUrl,
        if (permissions.isNotEmpty) 'permission': permissions,
        if (config.iconUrl != null && config.iconUrl!.isNotEmpty)
          'icon': config.iconUrl!,
      };

      final authUri = Uri(
        scheme: 'https',
        host: config.host,
        path: '/miauth/$sessionId',
        queryParameters: query,
      );

      // 3. ブラウザで認証ページを開く
      try {
        await FlutterWebAuth2.authenticate(
          url: authUri.toString(),
          callbackUrlScheme: config.callbackScheme,
        );
      } on PlatformException catch (e) {
        final code = (e.code).toLowerCase();
        if (code.contains('cancel')) {
          throw const UserCancelledException();
        }
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

      // 4. 許可後にチェック API を叩いてトークンを取得
      final checkUrl = Uri(
        scheme: 'https',
        host: config.host,
        path: '/api/miauth/$sessionId/check',
      );

      final response = await retry(
        () => _dio.post(
          checkUrl.toString(),
          options: Options(contentType: 'application/json'),
          data: <String, dynamic>{},
        ),
        const RetryPolicy(maxAttempts: 3),
      );

      if (response.statusCode != 200) {
        throw _checkError(response.statusCode, response.data);
      }

      final check = MiAuthCheckResponse.fromJson(jsonObjectOf(response.data));
      // Misskey は未知・取得済みのセッションにも ok:false を返すため、
      // 拒否以外の原因も含む
      if (!check.ok) {
        throw const MiAuthDeniedException();
      }
      final token = check.token;
      if (token == null || token.isEmpty) {
        throw const ResponseParseException(
          details: 'MiAuth check returned ok without a token',
        );
      }

      // 5. 成功応答（保存は呼び出し側で TokenStore が担当）
      return MiAuthTokenResponse(token: token, user: check.user);
    } on MisskeyAuthException {
      rethrow;
    } on DioException catch (e) {
      final response = e.response;
      if (e.type == DioExceptionType.badResponse && response != null) {
        throw _checkError(response.statusCode, response.data);
      }
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
    } on FormatException catch (e) {
      throw ResponseParseException(details: e.message, originalException: e);
    } catch (e) {
      throw MisskeyAuthException('MiAuthでエラーが発生しました', details: e.toString());
    }
  }

  /// チェック API のエラー応答を例外に変換
  MisskeyAuthException _checkError(int? status, Object? data) {
    final summary = errorSummaryOf(data);
    final details = summary == null
        ? 'status=$status'
        : 'status=$status, $summary';
    // セッション不正や期限切れなどをある程度推定
    if (status == 404 || status == 410) {
      return MiAuthSessionInvalidException(details: details);
    }
    return MiAuthCheckFailedException(details: details);
  }
}
