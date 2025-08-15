import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';

import '../models/miauth_models.dart';
import '../exceptions/misskey_auth_exception.dart';

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

  /// ランダムなセッション ID を生成（URL セーフな英数字）
  String generateSessionId({int length = 32}) {
    const charset =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)])
        .join();
  }

  /// MiAuth 認証を開始し、成功すればアクセストークンを返す
  Future<MiAuthTokenResponse> authenticate(MisskeyMiAuthConfig config) async {
    try {
      // 1. セッション ID を生成
      final sessionId = generateSessionId();
      if (kDebugMode) {
        print('MiAuth セッション: $sessionId');
      }

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

      if (kDebugMode) {
        print('MiAuth URL: $authUri');
      }

      // 3. ブラウザで認証ページを開く
      late final String result;
      try {
        result = await FlutterWebAuth2.authenticate(
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
              details: e.message, originalException: e);
        }
        throw AuthorizationLaunchException(
            details: e.message, originalException: e);
      } catch (e) {
        if (e is MisskeyAuthException) rethrow;
        throw AuthorizationLaunchException(details: e.toString());
      }

      if (kDebugMode) {
        print('MiAuth コールバック URL: $result');
      }

      // 4. 許可後にチェック API を叩いてトークンを取得
      final checkUrl = Uri(
        scheme: 'https',
        host: config.host,
        path: '/api/miauth/$sessionId/check',
      );

      final response = await _dio.post(
        checkUrl.toString(),
        options: Options(contentType: 'application/json'),
        data: <String, dynamic>{},
      );

      if (response.statusCode != 200) {
        final status = response.statusCode;
        String details = 'status=$status';
        final data = response.data;
        if (data is Map<String, dynamic>) {
          final err = data['error'] ?? data['message'];
          if (err != null) {
            details = '$details, $err';
          }
        }
        // セッション不正や期限切れなどをある程度推定
        if (status == 404 || status == 410) {
          throw MiAuthSessionInvalidException(details: details);
        }
        throw MiAuthCheckFailedException(details: details);
      }

      final body = response.data as Map<String, dynamic>;
      final check = MiAuthCheckResponse.fromJson(body);

      if (!check.ok || check.token == null || check.token!.isEmpty) {
        throw const MiAuthDeniedException();
      }

      // 5. 成功応答（保存は呼び出し側で TokenStore が担当）
      if (kDebugMode) print('MiAuth 成功');
      return MiAuthTokenResponse(token: check.token!, user: check.user);
    } on MisskeyAuthException {
      rethrow;
    } on DioException catch (e) {
      throw NetworkException(details: e.message, originalException: e);
    } on PlatformException catch (e) {
      final code = (e.code).toLowerCase();
      if (code.contains('cancel')) {
        throw const UserCancelledException();
      }
      throw AuthorizationLaunchException(
          details: e.message, originalException: e);
    } on FormatException catch (e) {
      throw ResponseParseException(details: e.message, originalException: e);
    } catch (e) {
      if (kDebugMode) {
        print('MiAuth エラー: $e');
      }
      throw MisskeyAuthException('MiAuthでエラーが発生しました', details: e.toString());
    }
  }

  // ストレージ操作は廃止
}
