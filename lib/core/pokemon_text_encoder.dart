class PokemonTextEncoder {
  static const int terminator = 0x50;
  static const int maxLength = 10;

  static List<int> encode(String text) {
    if (text.length > maxLength) {
      throw ArgumentError('El nombre no puede superar los 10 caracteres.');
    }

    final bytes = <int>[];

    for (final char in text.split('')) {
      final code = char.codeUnitAt(0);

      // Letras mayúsculas A-Z
      if (code >= 65 && code <= 90) {
        bytes.add(0x80 + (code - 65));
      }
      // Letras minúsculas a-z
      else if (code >= 97 && code <= 122) {
        bytes.add(0xA0 + (code - 97));
      }
      // Números 0-9
      else if (code >= 48 && code <= 57) {
        bytes.add(0xF6 + (code - 48));
      }
      // Espacio
      else if (char == ' ') {
        bytes.add(0x7F);
      }
      // Guion
      else if (char == '-') {
        bytes.add(0xE3);
      }
      // Caracteres no compatibles
      else {
        throw ArgumentError('Carácter no compatible: $char');
      }
    }

    // Terminador del nombre
    bytes.add(terminator);

    // Cada apodo ocupa exactamente 11 bytes
    while (bytes.length < 11) {
      bytes.add(terminator);
    }

    return bytes;
  }
}
