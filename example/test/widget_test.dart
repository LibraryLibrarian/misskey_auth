import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:misskey_auth_example/i18n/strings.g.dart';
import 'package:misskey_auth_example/main.dart';

Widget _app() => TranslationProvider(child: const MyApp());

void main() {
  tearDown(() => LocaleSettings.setLocaleSync(AppLocale.en));

  testWidgets('OAuth and MiAuth forms remain accessible', (tester) async {
    LocaleSettings.setLocaleSync(AppLocale.en);
    await tester.pumpWidget(_app());
    expect(find.text('Misskey Auth Sample'), findsOneWidget);
    expect(find.text('Sign in with OAuth'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.vpn_key));
    await tester.pumpAndSettle();
    expect(find.text('Sign in with MiAuth'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.lock));
    await tester.pumpAndSettle();
    expect(find.text('Sign in with OAuth'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows Japanese text when the locale is ja', (tester) async {
    LocaleSettings.setLocaleSync(AppLocale.ja);
    await tester.pumpWidget(_app());
    expect(find.text('OAuthで認証'), findsOneWidget);
    expect(find.text('サーバー情報'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
