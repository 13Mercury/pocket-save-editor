import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_save_editor/core/pokemon_species.dart';

void main() {
  test('Crystal catalog covers all 251 species without gaps', () {
    expect(PokemonSpecies.gen2.length, 251);
    for (var id = 1; id <= 251; id++) {
      expect(PokemonSpecies.gen2[id], isNotEmpty);
    }
    expect(PokemonSpecies.getName(1), 'Bulbasaur');
    expect(PokemonSpecies.getName(42), 'Golbat');
    expect(PokemonSpecies.getName(151), 'Mew');
    expect(PokemonSpecies.getName(152), 'Chikorita');
    expect(PokemonSpecies.getName(251), 'Celebi');
  });

  test('Invalid IDs use fallback and never request a sprite', () {
    for (final id in [-1, 0, 252, 255]) {
      expect(PokemonSpecies.getName(id), 'Unknown (#$id)');
      expect(PokemonSpecies.crystalSpriteUrl(id), isNull);
    }
    expect(
      PokemonSpecies.crystalSpriteUrl(42),
      endsWith('/crystal/transparent/42.png'),
    );
  });
}
