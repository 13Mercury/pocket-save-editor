class PokemonTextDecoder {
  static String decode(List<int> bytes) {
    final buffer = StringBuffer();

    for (final byte in bytes) {
      // Terminador de texto de Pokémon.
      if (byte == 0x50) {
        break;
      }

      // Letras mayúsculas A-Z.
      if (byte >= 0x80 && byte <= 0x99) {
        buffer.write(String.fromCharCode('A'.codeUnitAt(0) + byte - 0x80));
      }
      // Letras minúsculas a-z.
      else if (byte >= 0xA0 && byte <= 0xB9) {
        buffer.write(String.fromCharCode('a'.codeUnitAt(0) + byte - 0xA0));
      }
      // Espacio.
      else if (byte == 0x7F) {
        buffer.write(' ');
      }
      // Números 0-9.
      else if (byte >= 0xF6 && byte <= 0xFF) {
        buffer.write(byte - 0xF6);
      }
      // Guion.
      else if (byte == 0xE3) {
        buffer.write('-');
      }
      // Caracteres todavía no implementados.
      else {
        buffer.write('?');
      }
    }

    return buffer.toString();
  }
}
