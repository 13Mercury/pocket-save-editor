import 'dart:typed_data';

class CrystalChecksum {
  static const int primaryStart = 0x2009;
  static const int primaryEnd = 0x2B82;
  static const int primaryChecksumOffset = 0x2D0D;

  static const int backupStart = 0x1209;
  static const int backupEnd = 0x1D82;
  static const int backupChecksumOffset = 0x1F0D;

  static int calculate(Uint8List data, int start, int end) {
    int sum = 0;

    // El último byte también forma parte del cálculo.
    for (int i = start; i <= end; i++) {
      sum = (sum + data[i]) & 0xFFFF;
    }

    return sum;
  }

  static int readStored(Uint8List data, int offset) {
    // Little-endian: primero el byte menos significativo.
    return data[offset] | (data[offset + 1] << 8);
  }

  static bool isPrimaryValid(Uint8List data) {
    return calculate(data, primaryStart, primaryEnd) ==
        readStored(data, primaryChecksumOffset);
  }

  static bool isBackupValid(Uint8List data) {
    return calculate(data, backupStart, backupEnd) ==
        readStored(data, backupChecksumOffset);
  }

  static void update(Uint8List data) {
    // Calcular el checksum principal.
    final primary = calculate(data, primaryStart, primaryEnd);

    // Guardarlo en formato little-endian.
    data[primaryChecksumOffset] = primary & 0xFF;
    data[primaryChecksumOffset + 1] = (primary >> 8) & 0xFF;
  }

  static void synchronizeBackup(Uint8List data) {
    final length = primaryEnd - primaryStart + 1;

    // Copiar los datos principales al respaldo.
    final primaryData = Uint8List.fromList(
      data.sublist(primaryStart, primaryStart + length),
    );

    data.setRange(backupStart, backupStart + length, primaryData);

    // Actualizar checksum principal.
    final primary = calculate(data, primaryStart, primaryEnd);

    data[primaryChecksumOffset] = primary & 0xFF;
    data[primaryChecksumOffset + 1] = (primary >> 8) & 0xFF;

    // Actualizar checksum del respaldo.
    final backup = calculate(data, backupStart, backupEnd);

    data[backupChecksumOffset] = backup & 0xFF;
    data[backupChecksumOffset + 1] = (backup >> 8) & 0xFF;
  }
}
