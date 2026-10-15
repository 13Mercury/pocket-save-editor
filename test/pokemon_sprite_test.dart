import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_save_editor/widgets/pokemon_sprite.dart';

void main() {
  testWidgets('Unknown species displays fallback without an image', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: PokemonSprite(speciesId: 0)),
    );
    expect(find.byIcon(Icons.catching_pokemon), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('Failed image displays fallback', (tester) async {
    // Flutter widget tests reject network requests with HTTP 400.
    await tester.pumpWidget(
      const MaterialApp(home: PokemonSprite(speciesId: 42)),
    );
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.catching_pokemon), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Shiny Crystal sprite selects the shiny sprite asset', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: PokemonSprite(speciesId: 42, isShiny: true)),
    );
    final image = tester.widget<Image>(find.byType(Image));
    expect(
      (image.image as NetworkImage).url,
      endsWith('/crystal/shiny/42.png'),
    );
  });
}
