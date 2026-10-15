import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_save_editor/main.dart';

void main() {
  testWidgets('Pocket Save Editor muestra la pantalla inicial', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const PocketSaveEditorApp());

    expect(find.text('Pocket Save Editor'), findsOneWidget);
    expect(find.text('Import Save File'), findsOneWidget);
    expect(find.byIcon(Icons.folder_open), findsOneWidget);
  });
}
