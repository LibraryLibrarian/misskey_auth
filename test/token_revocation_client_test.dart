import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:misskey_auth/misskey_auth.dart';

import 'support/fakes.dart';

const _token = 'synthetic-secret-token';

/// Misskey API 形式のエラー応答
ResponseBody apiError(int status, String code) => jsonBody({
  'error': {'message': 'm', 'code': code, 'id': 'x'},
}, status);

ResponseBody textBody(String body, int status, String contentType) {
  return ResponseBody.fromString(
    body,
    status,
    headers: {
      Headers.contentTypeHeader: [contentType],
    },
  );
}

void main() {
  late List<RequestOptions> requests;

  /// [respond] を返す Dio で組み立てたクライアント
  MisskeyTokenRevocationClient clientWith(
    FutureOr<ResponseBody> Function(RequestOptions) respond, {
    bool acceptAllStatuses = false,
  }) {
    final dio = Dio(
      acceptAllStatuses ? BaseOptions(validateStatus: (_) => true) : null,
    );
    dio.httpClientAdapter = StubAdapter((options) {
      requests.add(options);
      return respond(options);
    });
    addTearDown(() => dio.close(force: true));
    return MisskeyTokenRevocationClient(dio: dio);
  }

  Future<TokenRevocationResult> revokeWith(
    FutureOr<ResponseBody> Function(RequestOptions) respond, {
    bool acceptAllStatuses = false,
    Duration? timeout,
  }) {
    return clientWith(
      respond,
      acceptAllStatuses: acceptAllStatuses,
    ).revoke(host: 'example.test', accessToken: _token, timeout: timeout);
  }

  setUp(() => requests = []);

  test('posts the token to revoke-token once', () async {
    final result = await revokeWith((_) => ResponseBody.fromString('', 204));
    expect(result.status, TokenRevocationStatus.revoked);
    expect(result.isInvalidated, isTrue);
    expect(result.error, isNull);
    final request = requests.single;
    expect(request.method, 'POST');
    expect(request.uri.toString(), 'https://example.test/api/i/revoke-token');
    expect(request.data, {'i': _token, 'token': _token});
  });

  group('classification', () {
    final cases =
        <String, (ResponseBody Function(), TokenRevocationStatus, String?)>{
          '204': (
            () => ResponseBody.fromString('', 204),
            TokenRevocationStatus.revoked,
            null,
          ),
          '200 HTML': (
            () => textBody('<html></html>', 200, 'text/html'),
            TokenRevocationStatus.failed,
            null,
          ),
          '401 AUTHENTICATION_FAILED': (
            () => apiError(401, 'AUTHENTICATION_FAILED'),
            TokenRevocationStatus.alreadyInvalid,
            'AUTHENTICATION_FAILED',
          ),
          '401 CREDENTIAL_REQUIRED': (
            () => apiError(401, 'CREDENTIAL_REQUIRED'),
            TokenRevocationStatus.failed,
            'CREDENTIAL_REQUIRED',
          ),
          '401 without body': (
            () => ResponseBody.fromString('', 401),
            TokenRevocationStatus.failed,
            null,
          ),
          '400 ACCESS_DENIED': (
            () => apiError(400, 'ACCESS_DENIED'),
            TokenRevocationStatus.unsupported,
            'ACCESS_DENIED',
          ),
          '400 INVALID_PARAM': (
            () => apiError(400, 'INVALID_PARAM'),
            TokenRevocationStatus.failed,
            'INVALID_PARAM',
          ),
          '403 PERMISSION_DENIED': (
            () => apiError(403, 'PERMISSION_DENIED'),
            TokenRevocationStatus.failed,
            'PERMISSION_DENIED',
          ),
          '404': (
            () => textBody('Not Found', 404, 'text/plain'),
            TokenRevocationStatus.unsupported,
            null,
          ),
          '429': (
            () => apiError(429, 'RATE_LIMIT_EXCEEDED'),
            TokenRevocationStatus.failed,
            'RATE_LIMIT_EXCEEDED',
          ),
          '500': (
            () => apiError(500, 'INTERNAL_ERROR'),
            TokenRevocationStatus.failed,
            'INTERNAL_ERROR',
          ),
          '502 text body': (
            () => textBody('Bad Gateway', 502, 'text/plain'),
            TokenRevocationStatus.failed,
            null,
          ),
        };

    for (final acceptAll in [false, true]) {
      group(
        acceptAll ? 'with validateStatus accepting all' : 'default Dio',
        () {
          cases.forEach((name, c) {
            final (body, status, errorCode) = c;
            test(name, () async {
              final result = await revokeWith(
                (_) => body(),
                acceptAllStatuses: acceptAll,
              );
              expect(result.status, status);
              expect(result.errorCode, errorCode);
              expect(result.statusCode, isNotNull);
              expect(requests, hasLength(1));
              if (status == TokenRevocationStatus.unsupported ||
                  status == TokenRevocationStatus.failed) {
                expect(result.error, isA<TokenRevocationException>());
              } else {
                expect(result.error, isNull);
              }
            });
          });
        },
      );
    }
  });

  test('classifies by the error code even for a short token', () async {
    // トークンを伏せる処理がエラーコードの判定に影響しない
    Future<TokenRevocationResult> revokeShort(ResponseBody body) =>
        clientWith((_) => body).revoke(host: 'example.test', accessToken: 'A');
    final invalid = await revokeShort(apiError(401, 'AUTHENTICATION_FAILED'));
    expect(invalid.status, TokenRevocationStatus.alreadyInvalid);
    final unsupported = await revokeShort(apiError(400, 'ACCESS_DENIED'));
    expect(unsupported.status, TokenRevocationStatus.unsupported);
  });

  test('does not retry after a server error', () async {
    final result = await revokeWith(
      (_) => apiError(503, 'SERVICE_UNAVAILABLE'),
    );
    expect(result.status, TokenRevocationStatus.failed);
    expect(requests, hasLength(1));
  });

  test('reports a connection error as a network failure', () async {
    final result = await revokeWith(
      (options) => throw DioException.connectionError(
        requestOptions: options,
        reason: 'refused',
      ),
    );
    expect(result.status, TokenRevocationStatus.failed);
    expect(result.statusCode, isNull);
    expect(result.error, isA<NetworkException>());
    expect(result.error!.originalException, isNull);
  });

  test('classifies a malformed JSON body by status', () async {
    final failed = await revokeWith(
      (_) => textBody('{not json', 500, 'application/json'),
    );
    expect(failed.status, TokenRevocationStatus.failed);
    expect(failed.statusCode, 500);
    expect(failed.error, isA<TokenRevocationException>());
    final unsupported = await revokeWith(
      (_) => textBody('{not json', 404, 'application/json'),
    );
    expect(unsupported.status, TokenRevocationStatus.unsupported);
    expect(unsupported.statusCode, 404);
  });

  test('reports an exception from an interceptor as a failure', () async {
    final dio = Dio()
      ..interceptors.add(
        InterceptorsWrapper(onRequest: (_, _) => throw StateError('boom')),
      )
      ..httpClientAdapter = StubAdapter(
        (_) => ResponseBody.fromString('', 204),
      );
    addTearDown(() => dio.close(force: true));
    final result = await MisskeyTokenRevocationClient(dio: dio)
        .revoke(host: 'example.test', accessToken: _token);
    expect(result.status, TokenRevocationStatus.failed);
    expect(result.error, isA<MisskeyAuthException>());
  });

  test('never exposes the token in the result', () async {
    final results = [
      await revokeWith((_) => apiError(500, 'INTERNAL_ERROR')),
      await revokeWith(
        (options) => throw DioException.connectionError(
          requestOptions: options,
          reason: 'refused',
        ),
      ),
      await revokeWith((_) => textBody('{', 500, 'application/json')),
      // サーバーやインターセプターがトークンを文言に含めた場合
      await revokeWith(
        (_) => jsonBody({
          'error': {'message': 'Invalid token: $_token', 'code': _token},
        }, 400),
      ),
      await revokeWith(
        (options) => throw DioException.connectionError(
          requestOptions: options,
          reason: 'refused for $_token',
        ),
      ),
    ];
    for (final result in results) {
      expect(result.toString(), isNot(contains(_token)));
      expect(result.errorCode ?? '', isNot(contains(_token)));
      expect(result.error.toString(), isNot(contains(_token)));
      expect(result.error!.details ?? '', isNot(contains(_token)));
      expect(result.error!.originalException, isNull);
    }
  });

  group('timeout', () {
    test('gives up on a request that never completes', () async {
      final never = Completer<ResponseBody>();
      final stopwatch = Stopwatch()..start();
      final result = await revokeWith(
        (_) => never.future,
        timeout: const Duration(milliseconds: 50),
      );
      expect(stopwatch.elapsed, lessThan(const Duration(seconds: 5)));
      expect(result.status, TokenRevocationStatus.failed);
      expect(result.error, isA<NetworkException>());
    });

    test('returns even if an interceptor never handles the cancel', () async {
      final dio = Dio()
        ..interceptors.add(
          // エラーを受け取っても handler を呼ばない
          InterceptorsWrapper(onError: (_, _) {}),
        )
        ..httpClientAdapter = StubAdapter(
          (_) => Completer<ResponseBody>().future,
        );
      addTearDown(() => dio.close(force: true));
      final result = await MisskeyTokenRevocationClient(dio: dio)
          .revoke(
            host: 'example.test',
            accessToken: _token,
            timeout: const Duration(milliseconds: 50),
          )
          .timeout(const Duration(seconds: 5));
      expect(result.status, TokenRevocationStatus.failed);
      expect(result.error, isA<NetworkException>());
    });

    test('does not send a request when no time is left', () async {
      final result = await revokeWith(
        (_) => ResponseBody.fromString('', 204),
        timeout: Duration.zero,
      );
      expect(result.status, TokenRevocationStatus.failed);
      expect(requests, isEmpty);
    });

    test('a completed request is not affected by the timeout', () async {
      final result = await revokeWith(
        (_) => ResponseBody.fromString('', 204),
        timeout: const Duration(seconds: 5),
      );
      expect(result.status, TokenRevocationStatus.revoked);
    });
  });

  test('applies timeout arguments without changing the injected Dio', () async {
    final dio = Dio(BaseOptions(receiveTimeout: const Duration(seconds: 3)));
    RequestOptions? sent;
    dio.httpClientAdapter = StubAdapter((options) {
      sent = options;
      return ResponseBody.fromString('', 204);
    });
    addTearDown(() => dio.close(force: true));
    await MisskeyTokenRevocationClient(
      dio: dio,
      receiveTimeout: const Duration(seconds: 7),
    ).revoke(host: 'example.test', accessToken: _token);
    expect(sent!.receiveTimeout, const Duration(seconds: 7));
    expect(dio.options.receiveTimeout, const Duration(seconds: 3));
  });
}
