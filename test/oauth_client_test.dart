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
        '{"authorization_endpoint":"https://example.test/auth","token_endpoint":"https://example.test/token"}',
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
        'authorization_endpoint': 'https://example.test/auth',
        'token_endpoint': 42,
      }),
    );
    await expectLater(
      client.getOAuthServerInfo('example.test'),
      throwsA(isA<ResponseParseException>()),
    );
  });
}
