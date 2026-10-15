import 'dart:typed_data';

class SaveReader {
  static const int expectedSize = 32768;

  final Uint8List data;

  SaveReader(this.data);

  bool get hasValidSize {
    return data.length == expectedSize;
  }

  int get fileSize {
    return data.length;
  }

  int readByte(int offset) {
    if (offset < 0 || offset >= data.length) {
      throw RangeError('Invalid offset: $offset');
    }

    return data[offset];
  }

  String readHex(int offset) {
    return readByte(offset).toRadixString(16).padLeft(2, '0').toUpperCase();
  }
}
