import 'package:flutter_test/flutter_test.dart';

import 'package:pocket_save_editor/core/pokemon_text_encoder.dart';
import 'package:pocket_save_editor/core/pokemon_text_decoder.dart';

void main() {
  test('Codifica correctamente GPT-6', () {
    final bytes = PokemonTextEncoder.encode('GPT-6');

    expect(bytes.length, 11);

    expect(bytes, [
      0x86,
      0x8F,
      0x93,
      0xE3,
      0xFC,
      0x50,
      0x50,
      0x50,
      0x50,
      0x50,
      0x50,
    ]);
  });

  test('Codifica y decodifica un apodo', () {
    final bytes = PokemonTextEncoder.encode('GPT-6');

    final decoded = PokemonTextDecoder.decode(bytes);

    expect(decoded, 'GPT-6');
  });

  test('Rechaza nombres demasiado largos', () {
    expect(() => PokemonTextEncoder.encode('ABCDEFGHIJK'), throwsArgumentError);
  });

  test('Rechaza caracteres no compatibles', () {
    expect(() => PokemonTextEncoder.encode('PIKACHU!'), throwsArgumentError);
  });

  test('Permite nombres de 10 caracteres', () {
    final bytes = PokemonTextEncoder.encode('ABCDEFGHIJ');

    expect(bytes.length, 11);
    expect(bytes.last, 0x50);
  });
}
