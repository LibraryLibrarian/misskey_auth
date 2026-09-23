import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:misskey_auth/misskey_auth.dart';

import 'support/fakes.dart';

const _config = MisskeyMiAuthConfig(
  host: 'example.test',
  appName: 'Example',
  callbackScheme: 'exampleapp',
  permissions: ['read:account'],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Dio dio;
  late MisskeyMiAuthClient client;

  setUp(() {
    dio = Dio();
    client = MisskeyMiAuthClient(dio: dio);
    mockWebAuth(
      (launch) => 'exampleapp://?session=${launch.pathSegments.last}',
    );
  });
  tearDown(() {
    resetWebAuth();
    dio.close(force: true);
  });

  void respond(ResponseBody Function() body) {
    dio.httpClientAdapter = StubAdapter((_) => body());
  }

  test('returns the token from a successful check', () async {
    respond(
      () => jsonBody({
        'ok': true,
        'token': 'synthetic',
        'user': {'id': 'user1'},
      }),
    );
    final result = await client.authenticate(_config);
    expect(result.token, 'synthetic');
    expect(result.user!['id'], 'user1');
  });

  test('ok:false is reported as denied', () async {
    respond(() => jsonBody({'ok': false}));
    await expectLater(
      client.authenticate(_config),
      throwsA(isA<MiAuthDeniedException>()),
    );
  });

  test('missing ok is a parse error rather than a denial', () async {
    respond(() => jsonBody({'token': 'synthetic'}));
    await expectLater(
      client.authenticate(_config),
      throwsA(isA<ResponseParseException>()),
    );
  });

  test('ok:true without a token is a parse error', () async {
    respond(() => jsonBody({'ok': true}));
    await expectLater(
      client.authenticate(_config),
      throwsA(isA<ResponseParseException>()),
    );
  });

  test('404 check response is an invalid session', () async {
    respond(() => jsonBody({}, 404));
    await expectLater(
      client.authenticate(_config),
      throwsA(
        isA<MiAuthSessionInvalidException>().having(
          (e) => e.details,
          'details',
          contains('status=404'),
        ),
      ),
    );
  });

  test('404 is classified the same when Dio accepts all statuses', () async {
    dio.options.validateStatus = (_) => true;
    respond(() => jsonBody({}, 404));
    await expectLater(
      client.authenticate(_config),
      throwsA(isA<MiAuthSessionInvalidException>()),
    );
  });

  test('other error statuses are check failures', () async {
    respond(
      () => jsonBody({
        'error': {'code': 'SOMETHING', 'message': 'failed'},
      }, 400),
    );
    await expectLater(
      client.authenticate(_config),
      throwsA(
        isA<MiAuthCheckFailedException>().having(
          (e) => e.details,
          'details',
          'status=400, code=SOMETHING, message=failed',
        ),
      ),
    );
  });

  group('check is sent only once', () {
    test('after a 503 response', () async {
      var attempts = 0;
      dio.httpClientAdapter = StubAdapter((_) {
        attempts++;
        return jsonBody({}, 503);
      });
      await expectLater(
        client.authenticate(_config),
        throwsA(isA<MiAuthCheckFailedException>()),
      );
      expect(attempts, 1);
    });

    test('after a connection error', () async {
      var attempts = 0;
      dio.httpClientAdapter = StubAdapter((options) {
        attempts++;
        throw DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
        );
      });
      await expectLater(
        client.authenticate(_config),
        throwsA(isA<NetworkException>()),
      );
      expect(attempts, 1);
    });
  });
}
