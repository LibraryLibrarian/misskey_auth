import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:misskey_auth_example/main.dart';

void main() {
  testWidgets('OAuth and MiAuth forms remain accessible', (tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.text('Misskey Auth Sample'), findsOneWidget);
    expect(find.text('OAuthで認証'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.vpn_key));
    await tester.pumpAndSettle();
    expect(find.text('MiAuthで認証'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.lock));
    await tester.pumpAndSettle();
    expect(find.text('OAuthで認証'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
