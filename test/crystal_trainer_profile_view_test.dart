import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_save_editor/games/crystal/crystal_reader.dart';
import 'package:pocket_save_editor/widgets/crystal_trainer_profile_view.dart';

void main() {
  testWidgets('Trainer profile groups thousands with commas', (tester) async {
    final bytes = Uint8List(32768)
      ..setRange(0x23DC, 0x23DF, [0x01, 0x23, 0x45])
      ..setRange(0x23E3, 0x23E5, [0x94, 0x26]);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CrystalTrainerProfileView(
            reader: CrystalReader(bytes),
            onEdit: () {},
          ),
        ),
      ),
    );

    expect(find.text('\$12,345'), findsOneWidget);
    expect(find.text('9,876'), findsOneWidget);
    expect(find.byIcon(Icons.air), findsOneWidget);
    expect(find.byIcon(Icons.terrain), findsOneWidget);
  });
}
