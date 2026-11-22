import 'package:dipalza_movil/src/share/app.navigator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('pop sin pantalla que cerrar no lanza excepción (doble toque)', (tester) async {
    await tester.pumpWidget(MaterialApp(
      navigatorKey: AppNavigator.navigatorKey,
      home: const Text('inicio'),
    ));

    AppNavigator.pop();
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('inicio'), findsOneWidget);
  });

  testWidgets('pop cierra la pantalla de arriba', (tester) async {
    await tester.pumpWidget(MaterialApp(
      navigatorKey: AppNavigator.navigatorKey,
      home: const Text('inicio'),
    ));
    AppNavigator.navigatorKey.currentState!
        .push(MaterialPageRoute<void>(builder: (_) => const Text('segunda')));
    await tester.pumpAndSettle();

    AppNavigator.pop();
    await tester.pumpAndSettle();

    expect(find.text('segunda'), findsNothing);
    expect(find.text('inicio'), findsOneWidget);
  });
}
