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

  testWidgets('opens the license page from the AppBar', (tester) async {
    LocaleSettings.setLocaleSync(AppLocale.en);
    await tester.pumpWidget(_app());
    await tester.tap(find.byTooltip('Open source licenses'));
    // LicensePage はライセンスを非同期で読み込むため、
    // pumpAndSettle ではなく一定時間だけ進める
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(LicensePage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final locale in AppLocale.values) {
    testWidgets('renders every tab without overflow in ${locale.languageTag}', (
      tester,
    ) async {
      // スマートフォン相当の幅で、長い翻訳がはみ出さないことを確かめる
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      LocaleSettings.setLocaleSync(locale);
      await tester.pumpWidget(_app());
      for (final icon in [
        Icons.lock,
        Icons.vpn_key,
        Icons.info_outline,
        Icons.people,
      ]) {
        // AppBar のライセンスボタンも info_outline のため、タブの中に限定する
        await tester.tap(
          find.descendant(
            of: find.byType(NavigationBar),
            matching: find.byIcon(icon),
          ),
        );
        // アカウント一覧はセキュアストレージの応答を待ち続けるため、
        // pumpAndSettle ではなく一定時間だけ進める
        await tester.pump(const Duration(seconds: 1));
        expect(tester.takeException(), isNull);
      }
    });
  }
}
