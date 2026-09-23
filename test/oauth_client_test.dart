import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:misskey_auth/misskey_auth.dart';

import 'support/fakes.dart';

void main() {
  late Dio dio;
  late MisskeyOAuthClient client;
  setUp(() {
    dio = Dio();
    client = MisskeyOAuthClient(dio: dio);
  });
  tearDown(() => dio.close(force: true));

  test('PKCE challenge matches RFC 7636 test vector', () {
    expect(
      client.generateCodeChallenge(
        'dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk',
      ),
      'E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM',
    );
  });

  test('404 discovery response is treated as unsupported OAuth', () async {
    dio.httpClientAdapter = StubAdapter(
      (_) => ResponseBody.fromString('', 404),
    );
    expect(await client.getOAuthServerInfo('example.test'), isNull);
  });

  test('transient discovery failure retries and decodes JSON', () async {
    var attempts = 0;
    dio.httpClientAdapter = StubAdapter((options) {
      expect(
        options.path,
        'https://example.test/.well-known/oauth-authorization-server',
      );
      attempts++;
      if (attempts == 1) return ResponseBody.fromString('', 503);
      return ResponseBody.fromString(
        '{"issuer":"https://example.test","authorization_endpoint":"https://example.test/auth","token_endpoint":"https://example.test/token"}',
        200,
        headers: {
          Headers.contentTypeHeader: ['application/json'],
        },
      );
    });
    final info = await client.getOAuthServerInfo('example.test');
    expect(info!.tokenEndpoint, 'https://example.test/token');
    expect(attempts, 2);
  });

  test('token exchange preserves form fields and decodes JSON', () async {
    dio.httpClientAdapter = StubAdapter((options) {
      expect(options.method, 'POST');
      expect(options.contentType, 'application/x-www-form-urlencoded');
      expect(options.data['grant_type'], 'authorization_code');
      expect(options.data['code_verifier'], 'synthetic-verifier');
      expect(options.data['redirect_uri'], 'https://example.test/callback');
      return ResponseBody.fromString(
        '{"access_token":"synthetic-token","token_type":"Bearer"}',
        200,
        headers: {
          Headers.contentTypeHeader: ['application/json'],
        },
      );
    });
    final token = await client.exchangeCodeForToken(
      tokenEndpoint: 'https://example.test/token',
      clientId: 'https://example.test/app',
      redirectUri: 'https://example.test/callback',
      scope: 'read',
      code: 'synthetic-code',
      codeVerifier: 'synthetic-verifier',
    );
    expect(token.accessToken, 'synthetic-token');
  });

  Future<OAuthTokenResponse> exchange() => client.exchangeCodeForToken(
    tokenEndpoint: 'https://example.test/token',
    clientId: 'https://example.test/app',
    redirectUri: 'https://example.test/callback',
    scope: 'read',
    code: 'synthetic-code',
    codeVerifier: 'synthetic-verifier',
  );

  test('token endpoint error keeps TokenExchangeException', () async {
    dio.httpClientAdapter = StubAdapter(
      (_) => jsonBody({'error': 'invalid_grant'}, 400),
    );
    await expectLater(
      exchange(),
      throwsA(
        isA<TokenExchangeException>().having(
          (e) => e.message,
          'message',
          contains('error=invalid_grant'),
        ),
      ),
    );
  });

  test(
    'token endpoint error is not rewrapped when Dio accepts all statuses',
    () async {
      dio.options.validateStatus = (_) => true;
      dio.httpClientAdapter = StubAdapter(
        (_) => jsonBody({'error': 'invalid_grant'}, 400),
      );
      await expectLater(exchange(), throwsA(isA<TokenExchangeException>()));
    },
  );

  test('token response without access_token is a parse error', () async {
    dio.httpClientAdapter = StubAdapter(
      (_) => jsonBody({'token_type': 'Bearer'}),
    );
    await expectLater(exchange(), throwsA(isA<ResponseParseException>()));
  });

  test('malformed JSON token response is a parse error', () async {
    dio.httpClientAdapter = StubAdapter(
      (_) => ResponseBody.fromString(
        '{not json',
        200,
        headers: {
          Headers.contentTypeHeader: ['application/json'],
        },
      ),
    );
    await expectLater(exchange(), throwsA(isA<ResponseParseException>()));
  });

  test('discovery metadata with wrong field types is a parse error', () async {
    dio.httpClientAdapter = StubAdapter(
      (_) => jsonBody({
        'issuer': 'https://example.test',
        'authorization_endpoint': 'https://example.test/auth',
        'token_endpoint': 42,
      }),
    );
    await expectLater(
      client.getOAuthServerInfo('example.test'),
      throwsA(isA<ResponseParseException>()),
    );
  });

  group('token exchange is sent only once', () {
    late int attempts;
    setUp(() => attempts = 0);

    test('after a 503 response', () async {
      dio.httpClientAdapter = StubAdapter((_) {
        attempts++;
        return jsonBody({}, 503);
      });
      await expectLater(exchange(), throwsA(isA<TokenExchangeException>()));
      expect(attempts, 1);
    });

    test('after a receive timeout', () async {
      dio.httpClientAdapter = StubAdapter((options) {
        attempts++;
        throw DioException(
          requestOptions: options,
          type: DioExceptionType.receiveTimeout,
        );
      });
      await expectLater(exchange(), throwsA(isA<NetworkException>()));
      expect(attempts, 1);
    });
  });

  group('discovery metadata validation', () {
    Map<String, Object?> metadata([Map<String, Object?> overrides = const {}]) {
      return {
        'issuer': 'https://example.test',
        'authorization_endpoint': 'https://example.test/oauth/authorize',
        'token_endpoint': 'https://example.test/oauth/token',
        ...overrides,
      }..removeWhere((_, v) => v == null);
    }

    Future<OAuthServerInfo?> discover(
      Map<String, Object?> body, {
      String host = 'example.test',
    }) {
      dio.httpClientAdapter = StubAdapter((_) => jsonBody(body));
      return client.getOAuthServerInfo(host);
    }

    test('accepts an issuer matching the normalized host', () async {
      final info = await discover(metadata(), host: ' Example.TEST ');
      expect(info!.tokenEndpoint, 'https://example.test/oauth/token');
    });

    test('keeps a non-default port in the expected issuer', () async {
      final info = await discover(
        metadata({'issuer': 'https://example.test:3000'}),
        host: 'example.test:3000',
      );
      expect(info, isNotNull);
    });

    test('allows endpoints on another HTTPS origin', () async {
      final info = await discover(
        metadata({'token_endpoint': 'https://auth.example.test/token'}),
      );
      expect(info!.tokenEndpoint, 'https://auth.example.test/token');
    });

    test('does not put received URLs into the exception', () async {
      for (final body in [
        metadata({'issuer': 'https://user:secret@example.test'}),
        metadata({'token_endpoint': 'https://user:secret@example.test/token'}),
      ]) {
        await expectLater(
          discover(body),
          throwsA(
            isA<ServerInfoException>().having(
              (e) => e.toString(),
              'toString()',
              isNot(contains('secret')),
            ),
          ),
        );
      }
    });

    for (final entry in {
      'missing issuer': metadata({'issuer': null}),
      'issuer with a trailing slash': metadata({
        'issuer': 'https://example.test/',
      }),
      'issuer of another server': metadata({'issuer': 'https://evil.test'}),
      'HTTP authorization endpoint': metadata({
        'authorization_endpoint': 'http://example.test/oauth/authorize',
      }),
      'relative token endpoint': metadata({'token_endpoint': '/oauth/token'}),
      'token endpoint with user info': metadata({
        'token_endpoint': 'https://user@example.test/oauth/token',
      }),
      'token endpoint with a fragment': metadata({
        'token_endpoint': 'https://example.test/oauth/token#x',
      }),
    }.entries) {
      test('rejects ${entry.key}', () async {
        await expectLater(
          discover(entry.value),
          throwsA(isA<ServerInfoException>()),
        );
      });
    }
  });
}
