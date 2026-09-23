import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:misskey_auth/misskey_auth.dart';

import 'support/fakes.dart';

const _config = MisskeyOAuthConfig(
  host: 'example.test',
  clientId: 'https://app.example.test/',
  redirectUri: 'https://app.example.test/redirect',
  scope: 'read:account',
  callbackScheme: 'exampleapp',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Dio dio;
  late MisskeyOAuthClient client;
  late List<RequestOptions> requests;

  setUp(() {
    requests = [];
    dio = Dio()
      ..httpClientAdapter = StubAdapter((options) {
        requests.add(options);
        if (options.path.endsWith('/.well-known/oauth-authorization-server')) {
          return jsonBody({
            'issuer': 'https://example.test',
            'authorization_endpoint': 'https://example.test/oauth/authorize',
            'token_endpoint': 'https://example.test/oauth/token',
          });
        }
        return jsonBody({'access_token': 'synthetic', 'token_type': 'Bearer'});
      });
    client = MisskeyOAuthClient(dio: dio);
  });
  tearDown(() {
    resetWebAuth();
    dio.close(force: true);
  });

  /// 起動 URL の state をそのまま返す callback を組み立てる
  String callbackWith(Uri launch, Map<String, String> params) {
    final state = launch.queryParameters['state']!;
    return Uri(
      scheme: 'exampleapp',
      host: 'callback',
      queryParameters: {'state': state, ...params},
    ).toString();
  }

  test('accepts a short authorization code', () async {
    mockWebAuth((launch) => callbackWith(launch, {'code': 'abc'}));
    final token = await client.authenticate(_config);
    expect(token!.accessToken, 'synthetic');
    expect(requests.last.data['code'], 'abc');
  });

  test('rejects an empty authorization code without exchanging it', () async {
    mockWebAuth((launch) => callbackWith(launch, {'code': ''}));
    await expectLater(
      client.authenticate(_config),
      throwsA(isA<AuthorizationCodeMissingException>()),
    );
    expect(requests.where((r) => r.method == 'POST'), isEmpty);
  });

  group('callback validation', () {
    Future<void> expectRejected(
      String Function(Uri launch) callback,
      Matcher matcher,
    ) async {
      mockWebAuth(callback);
      await expectLater(client.authenticate(_config), throwsA(matcher));
      expect(requests.where((r) => r.method == 'POST'), isEmpty);
    }

    test('checks state before reporting an authorization error', () async {
      await expectRejected(
        (_) => 'exampleapp://callback?error=access_denied&state=forged',
        isA<StateMismatchException>(),
      );
    });

    test('rejects an error callback without state', () async {
      await expectRejected(
        (_) => 'exampleapp://callback?error=access_denied',
        isA<StateMismatchException>(),
      );
    });

    test('reports an authorization error with a matching state', () async {
      await expectRejected(
        (launch) => callbackWith(launch, {
          'error': 'access_denied',
          'error_description': 'denied',
        }),
        isA<AuthorizationServerErrorException>().having(
          (e) => e.details,
          'details',
          'error=access_denied, description=denied',
        ),
      );
    });

    test('rejects a duplicated state', () async {
      await expectRejected((launch) {
        final state = launch.queryParameters['state'];
        return 'exampleapp://callback?code=abc&state=$state&state=$state';
      }, isA<StateMismatchException>());
    });

    test('rejects duplicated codes', () async {
      await expectRejected((launch) {
        final state = launch.queryParameters['state'];
        return 'exampleapp://callback?code=abc&code=def&state=$state';
      }, isA<AuthorizationCodeMissingException>());
    });
  });
}
