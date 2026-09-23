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
}
