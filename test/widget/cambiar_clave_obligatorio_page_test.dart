import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:dipalza_movil/src/bloc/cambiar_clave_bloc.dart';
import 'package:dipalza_movil/src/page/login/cambiar_clave_obligatorio.page.dart';

void main() {
  Widget createWidgetUnderTest() {
    return MultiProvider(
      providers: [
        Provider<CambiarClaveBloc>(
          create: (_) => CambiarClaveBloc(),
          dispose: (_, bloc) => bloc.dispose(),
        ),
      ],
      child: const MaterialApp(
        home: CambiarClaveObligatorioPage(claveActual: 'ClaveTemp123'),
      ),
    );
  }

  testWidgets('no muestra el campo de clave actual', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());

    expect(find.text('Clave actual'), findsNothing);
    expect(find.text('Clave nueva'), findsOneWidget);
    expect(find.text('Confirmar clave nueva'), findsOneWidget);
  });

  testWidgets('no muestra botón de retroceso en el AppBar', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());

    expect(find.byType(BackButton), findsNothing);
  });
}
