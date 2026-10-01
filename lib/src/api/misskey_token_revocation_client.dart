import 'dart:async';

import 'package:dio/dio.dart';

import '../exceptions/misskey_auth_exception.dart';
import '../models/token_revocation_models.dart';
import '../net/response.dart';

/// アクセストークンをサーバー上で失効させるクライアント
///
/// Misskey 2026.9.0 以降の `/api/i/revoke-token` を使い、渡したトークン自身を
/// 失効させる。MiAuth と OAuth のどちらのトークンにも使え、権限は問わない。
/// 端末に保存したトークンは扱わない（`MisskeyAuthManager.signOut` を参照）
class MisskeyTokenRevocationClient {
  final Dio _dio;
  final Duration? _connectTimeout;
  final Duration? _sendTimeout;
  final Duration? _receiveTimeout;

  /// 失効の通信で使用するHTTPクライアント
  ///
  /// [dio] を渡さない場合は、次のデフォルトタイムアウトで初期化
  /// - 接続: 10秒
  /// - 送信:  20秒
  /// - 受信:  20秒
  ///
  /// [dio] を渡した場合、タイムアウトの引数はこのクライアントのリクエストにだけ
  /// 適用し、渡された `Dio` の設定は変更しない。渡した `Dio` のインターセプターは
  /// リクエストボディのトークンを参照できる点に注意
  MisskeyTokenRevocationClient({
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
           ),
       _connectTimeout = connectTimeout,
       _sendTimeout = sendTimeout,
       _receiveTimeout = receiveTimeout;

  /// [host] のサーバー上で [accessToken] を失効させる
  ///
  /// 例外は投げず、結果を [TokenRevocationResult] で返す。自動で再送しない。
  /// [timeout] を渡すと、リクエスト全体をその時間で打ち切り
  /// [TokenRevocationStatus.failed] を返す。打ち切った場合や応答を受け取れな
  /// かった場合でも、サーバー側では失効している可能性がある。再度呼ぶと
  /// [TokenRevocationStatus.alreadyInvalid] になる
  Future<TokenRevocationResult> revoke({
    required String host,
    required String accessToken,
    Duration? timeout,
  }) async {
    if (timeout != null && timeout <= Duration.zero) {
      return _timedOut(timeout);
    }
    // サーバーやインターセプターの文言がトークンを含んでも、結果に載せない
    String redact(String text) =>
        accessToken.isEmpty ? text : text.replaceAll(accessToken, '***');

    final cancelToken = CancelToken();
    final request = _send(host, accessToken, cancelToken, redact);
    if (timeout == null) return request;

    // キャンセル後にインターセプターが完了しない場合も、期限で結果を返す
    final expired = Completer<TokenRevocationResult>();
    final timer = Timer(timeout, () {
      cancelToken.cancel();
      expired.complete(_timedOut(timeout));
    });
    try {
      return await Future.any([request, expired.future]);
    } finally {
      timer.cancel();
    }
  }

  /// 失効のリクエストを送り、結果に変換する。例外は投げない
  Future<TokenRevocationResult> _send(
    String host,
    String accessToken,
    CancelToken cancelToken,
    String Function(String) redact,
  ) async {
    try {
      // 型を String にして Dio に JSON を解釈させない。不正な JSON でもステータスで分類する
      final response = await _dio.post<String>(
        'https://$host/api/i/revoke-token',
        data: <String, dynamic>{'i': accessToken, 'token': accessToken},
        options: Options(
          contentType: 'application/json',
          connectTimeout: _connectTimeout,
          sendTimeout: _sendTimeout,
          receiveTimeout: _receiveTimeout,
          // エラー応答も分類するため、ステータスでは例外にしない
          validateStatus: (_) => true,
        ),
        cancelToken: cancelToken,
      );
      return _classify(response.statusCode, response.data, redact);
    } on DioException catch (e) {
      final response = e.response;
      // インターセプターがエラー応答として reject した場合
      if (e.type == DioExceptionType.badResponse && response != null) {
        return _classify(response.statusCode, response.data, redact);
      }
      // キャンセルするのは期限のタイマーだけ（結果は revoke 側で返す）
      if (e.type == DioExceptionType.cancel) {
        return const TokenRevocationResult(
          status: TokenRevocationStatus.failed,
          error: NetworkException(details: 'The request was cancelled'),
        );
      }
      // DioException は送信データ（トークン）を持つため、原因に含めない
      final cause = e.error;
      if (cause is FormatException) {
        return TokenRevocationResult(
          status: TokenRevocationStatus.failed,
          statusCode: response?.statusCode,
          error: ResponseParseException(details: redact(cause.message)),
        );
      }
      return TokenRevocationResult(
        status: TokenRevocationStatus.failed,
        error: NetworkException(
          details: redact(e.message ?? 'type=${e.type.name}'),
        ),
      );
    } catch (e) {
      // インターセプターなどが投げた想定外の例外
      return TokenRevocationResult(
        status: TokenRevocationStatus.failed,
        error: MisskeyAuthException(
          'Token revocation failed unexpectedly.',
          details: e.runtimeType.toString(),
        ),
      );
    }
  }

  /// 応答をステータスとエラーコードで分類する
  TokenRevocationResult _classify(
    int? status,
    Object? data,
    String Function(String) redact,
  ) {
    if (status == 204) {
      return TokenRevocationResult(
        status: TokenRevocationStatus.revoked,
        statusCode: status,
      );
    }
    Map<String, dynamic>? body;
    try {
      body = jsonObjectOf(data);
    } on FormatException {
      body = null;
    }
    final error = body?['error'];
    final code = error is Map ? error['code'] : null;
    final errorCode = code is String ? redact(code) : null;

    // トークンが存在しない: 失効済み、またはアカウント削除済み
    if (status == 401 && errorCode == 'AUTHENTICATION_FAILED') {
      return TokenRevocationResult(
        status: TokenRevocationStatus.alreadyInvalid,
        statusCode: status,
        errorCode: errorCode,
      );
    }
    // 2026.9.0 未満はアプリのトークンからの呼び出しを ACCESS_DENIED で拒否する
    final unsupported =
        (status == 400 && errorCode == 'ACCESS_DENIED') || status == 404;
    final summary = body == null ? null : errorSummaryOf(body);
    return TokenRevocationResult(
      status: unsupported
          ? TokenRevocationStatus.unsupported
          : TokenRevocationStatus.failed,
      statusCode: status,
      errorCode: errorCode,
      error: TokenRevocationException(
        details: summary == null
            ? 'status=$status'
            : 'status=$status, ${redact(summary)}',
      ),
    );
  }

  TokenRevocationResult _timedOut(Duration timeout) => TokenRevocationResult(
    status: TokenRevocationStatus.failed,
    error: NetworkException(
      details: 'Timed out after ${timeout.inMilliseconds} ms',
    ),
  );
}
