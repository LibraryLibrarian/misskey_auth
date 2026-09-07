import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:misskey_auth/misskey_auth.dart';

class StubAdapter implements HttpClientAdapter {
  StubAdapter(this.respond);
  final ResponseBody Function(RequestOptions) respond;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => respond(options);

  @override
  void close({bool force = false}) {}
}

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
}
