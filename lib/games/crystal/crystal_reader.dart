import 'dart:typed_data';

import 'package:pocket_save_editor/core/pokemon_text_decoder.dart';
import 'package:pocket_save_editor/core/pokemon_text_encoder.dart';

import 'crystal_stats.dart';
import 'crystal_pokemon_moves.dart';
import 'crystal_experience.dart';
import 'crystal_pc_reader.dart';

class CrystalReader {
  final Uint8List data;

  CrystalReader(this.data);

  static const int partyCountOffset = 0x2865;
  static const int partySpeciesOffset = 0x2866;
  static const int partyNicknamesOffset = 0x29CF;
  static const int nicknameLength = 11;

  // Pokémon Crystal (international) save offsets, from PKHeX's SAV2Offsets.
  static const int trainerNameOffset = 0x200B;
  static const int rivalNameOffset = 0x2021;
  static const int moneyOffset = 0x23DC;
  static const int coinsOffset = 0x23E3;
  static const int johtoBadgesOffset = 0x23E5;
  static const int kantoBadgesOffset = 0x23E6;
  static const int pokedexCaughtOffset = 0x2A27;
  static const int pokedexSeenOffset = 0x2A47;
  static const int playerGenderOffset = 0x3E3D;

  static const List<String> johtoBadgeNames = [
    'Céfiro',
    'Colmena',
    'Planicie',
    'Niebla',
    'Tormenta',
    'Mineral',
    'Glaciar',
    'Dragón',
  ];
  static const List<String> kantoBadgeNames = [
    'Roca',
    'Cascada',
    'Trueno',
    'Arcoíris',
    'Alma',
    'Pantano',
    'Volcán',
    'Tierra',
  ];

  String get trainerName => _readGameName(trainerNameOffset);
  String get rivalName => _readGameName(rivalNameOffset);

  String _readGameName(int offset) =>
      PokemonTextDecoder.decode(data.sublist(offset, offset + nicknameLength));

  /// Crystal stores money as three packed-BCD bytes.
  int get money {
    var value = 0;
    for (var i = 0; i < 3; i++) {
      final byte = data[moneyOffset + i];
      value = value * 100 + (byte >> 4) * 10 + (byte & 0x0f);
    }
    return value;
  }

  int get coins => data[coinsOffset] | (data[coinsOffset + 1] << 8);

  bool get isFemale => (data[playerGenderOffset] & 1) == 1;

  bool _dexFlag(int speciesId, int offset) {
    if (speciesId < 1 || speciesId > 251) return false;
    final dexIndex = speciesId - 1;
    final byte = data[offset + dexIndex ~/ 8];
    return (byte & (1 << (dexIndex % 8))) != 0;
  }

  bool hasSeenSpecies(int speciesId) => _dexFlag(speciesId, pokedexSeenOffset);
  bool hasCaughtSpecies(int speciesId) =>
      _dexFlag(speciesId, pokedexCaughtOffset);

  int get seenSpeciesCount =>
      List.generate(251, (i) => i + 1).where(hasSeenSpecies).length;
  int get caughtSpeciesCount =>
      List.generate(251, (i) => i + 1).where(hasCaughtSpecies).length;

  List<bool> _badgesAt(int offset, List<String> names) =>
      List.generate(names.length, (bit) => (data[offset] & (1 << bit)) != 0);

  List<bool> get johtoBadges => _badgesAt(johtoBadgesOffset, johtoBadgeNames);
  List<bool> get kantoBadges => _badgesAt(kantoBadgesOffset, kantoBadgeNames);

  int get badgeCount =>
      [...johtoBadges, ...kantoBadges].where((earned) => earned).length;

  /// Updates only the trainer profile bytes; save checksums are left to the
  /// existing export flow.
  Uint8List withTrainerProfile({
    required String trainerName,
    required String rivalName,
    required int money,
    required int coins,
    required List<bool> johtoBadges,
    required List<bool> kantoBadges,
  }) {
    if (trainerName.trim().isEmpty || rivalName.trim().isEmpty) {
      throw ArgumentError(
        'El nombre del entrenador y del rival no puede estar vacío.',
      );
    }
    if (money < 0 || money > 999999) {
      throw RangeError.range(money, 0, 999999, 'money');
    }
    if (coins < 0 || coins > 9999) {
      throw RangeError.range(coins, 0, 9999, 'coins');
    }
    if (johtoBadges.length != 8 || kantoBadges.length != 8) {
      throw ArgumentError('Se requieren ocho medallas por región.');
    }

    final modified = Uint8List.fromList(data);
    modified.setRange(
      trainerNameOffset,
      trainerNameOffset + 11,
      PokemonTextEncoder.encode(trainerName.trim()),
    );
    modified.setRange(
      rivalNameOffset,
      rivalNameOffset + 11,
      PokemonTextEncoder.encode(rivalName.trim()),
    );
    for (var i = 0; i < 3; i++) {
      final divisor = [10000, 100, 1][i];
      final pair = money ~/ divisor % 100;
      modified[moneyOffset + i] = ((pair ~/ 10) << 4) | (pair % 10);
    }
    modified[coinsOffset] = coins & 0xff;
    modified[coinsOffset + 1] = (coins >> 8) & 0xff;
    modified[johtoBadgesOffset] = _badgeByte(johtoBadges);
    modified[kantoBadgesOffset] = _badgeByte(kantoBadges);
    return modified;
  }

  static int _badgeByte(List<bool> badges) {
    var value = 0;
    for (var i = 0; i < badges.length; i++) {
      if (badges[i]) value |= 1 << i;
    }
    return value;
  }

  int get partyCount {
    return data[partyCountOffset];
  }

  List<int> get partySpecies {
    final count = partyCount;

    if (count > 6) {
      throw FormatException('Cantidad de Pokémon inválida: $count');
    }

    return List.generate(count, (index) => data[partySpeciesOffset + index]);
  }

  List<String> get partyNicknames {
    final names = <String>[];

    for (int i = 0; i < partyCount; i++) {
      final offset = partyNicknamesOffset + (i * nicknameLength);

      final nameBytes = data.sublist(offset, offset + nicknameLength);

      names.add(PokemonTextDecoder.decode(nameBytes));
    }

    return names;
  }

  Uint8List withPartyNickname(int pokemonIndex, String newNickname) {
    if (pokemonIndex < 0 || pokemonIndex >= partyCount) {
      throw RangeError('Índice de Pokémon inválido');
    }

    // Crear una copia independiente de la partida.
    final modifiedData = Uint8List.fromList(data);

    // Convertir el nuevo apodo a bytes.
    final nicknameBytes = PokemonTextEncoder.encode(newNickname);

    // Calcular la posición del apodo.
    final offset = partyNicknamesOffset + (pokemonIndex * nicknameLength);

    // Reemplazar únicamente los 11 bytes del apodo.
    modifiedData.setRange(offset, offset + nicknameLength, nicknameBytes);

    return modifiedData;
  }

  Uint8List withPartyMoves(int index, List<CrystalMoveSlot> moves) {
    _checkPartyIndex(index);
    final modified = Uint8List.fromList(data);
    writeCrystalMoves(modified, 0x286D + index * 48, moves);
    return modified;
  }

  int partyHeldItemId(int index) {
    _checkPartyIndex(index);
    return data[0x286d + index * 48 + 1];
  }

  Uint8List withPartyHeldItem(int index, int itemId) {
    _checkPartyIndex(index);
    if (itemId < 0 || itemId > 255) {
      throw RangeError.range(itemId, 0, 255, 'itemId');
    }
    final modified = Uint8List.fromList(data);
    modified[0x286d + index * 48 + 1] = itemId;
    return modified;
  }

  int boxHeldItemId(int boxIndex, int slotIndex) =>
      data[_boxRecordOffset(boxIndex, slotIndex) + 1];

  String boxNickname(int boxIndex, int slotIndex) {
    final offset = CrystalPcReader.boxNicknameOffset(boxIndex, slotIndex);
    return PokemonTextDecoder.decode(data.sublist(offset, offset + 11));
  }

  int boxFriendship(int boxIndex, int slotIndex) =>
      data[_boxRecordOffset(boxIndex, slotIndex) + 27];

  int boxPokerusStatus(int boxIndex, int slotIndex) =>
      data[_boxRecordOffset(boxIndex, slotIndex) + 28];

  Map<String, int> boxStatExperience(int boxIndex, int slotIndex) {
    final offset = _boxRecordOffset(boxIndex, slotIndex) + 11;
    return {
      'hp': _readWord(data, offset),
      'attack': _readWord(data, offset + 2),
      'defense': _readWord(data, offset + 4),
      'speed': _readWord(data, offset + 6),
      'special': _readWord(data, offset + 8),
    };
  }

  Map<String, int> boxDvs(int boxIndex, int slotIndex) {
    final offset = _boxRecordOffset(boxIndex, slotIndex) + 21;
    return {
      'attack': data[offset] >> 4,
      'defense': data[offset] & 15,
      'speed': data[offset + 1] >> 4,
      'special': data[offset + 1] & 15,
    };
  }

  Uint8List withBoxNickname(int boxIndex, int slotIndex, String nickname) {
    _boxRecordOffset(boxIndex, slotIndex);
    final modified = Uint8List.fromList(data);
    final offset = CrystalPcReader.boxNicknameOffset(boxIndex, slotIndex);
    modified.setRange(
      offset,
      offset + 11,
      PokemonTextEncoder.encode(nickname),
    );
    return modified;
  }

  Uint8List withBoxHeldItem(int boxIndex, int slotIndex, int itemId) {
    if (itemId < 0 || itemId > 255) {
      throw RangeError.range(itemId, 0, 255, 'itemId');
    }
    final modified = Uint8List.fromList(data);
    modified[_boxRecordOffset(boxIndex, slotIndex) + 1] = itemId;
    return modified;
  }

  Uint8List withBoxMoves(
    int boxIndex,
    int slotIndex,
    List<CrystalMoveSlot> moves,
  ) {
    final modified = Uint8List.fromList(data);
    writeCrystalMoves(modified, _boxRecordOffset(boxIndex, slotIndex), moves);
    return modified;
  }

  Uint8List withBoxFriendship(int boxIndex, int slotIndex, int friendship) {
    if (friendship < 0 || friendship > 255) {
      throw RangeError.range(friendship, 0, 255, 'friendship');
    }
    final modified = Uint8List.fromList(data);
    modified[_boxRecordOffset(boxIndex, slotIndex) + 27] = friendship;
    return modified;
  }

  Uint8List withBoxPokerusStatus(int boxIndex, int slotIndex, int status) {
    if (status < 0 || status > 255 || (status & 15) > 4) {
      throw RangeError.range(status, 0, 0xf4, 'Pokérus');
    }
    final modified = Uint8List.fromList(data);
    modified[_boxRecordOffset(boxIndex, slotIndex) + 28] = status;
    return modified;
  }

  Uint8List withBoxLevel(int boxIndex, int slotIndex, int level) {
    if (level < 1 || level > 100) {
      throw RangeError.range(level, 1, 100, 'level');
    }
    final recordOffset = _boxRecordOffset(boxIndex, slotIndex);
    final speciesId = data[recordOffset];
    final oldLevel = data[recordOffset + 31];
    if (oldLevel < 1 || oldLevel > 100) {
      throw const FormatException('Nivel actual inválido.');
    }
    final oldMinimum = CrystalExperience.forLevel(speciesId, oldLevel);
    final oldMaximum = oldLevel == 100
        ? oldMinimum + 1
        : CrystalExperience.forLevel(speciesId, oldLevel + 1);
    final oldProgress = (boxExperience(boxIndex, slotIndex) - oldMinimum)
        .clamp(0, oldMaximum - oldMinimum - 1)
        .toInt();
    final newMinimum = CrystalExperience.forLevel(speciesId, level);
    final newMaximum = level == 100
        ? newMinimum + 1
        : CrystalExperience.forLevel(speciesId, level + 1);
    final newProgress =
        oldProgress * (newMaximum - newMinimum) ~/ (oldMaximum - oldMinimum);
    final experience = newMinimum + newProgress;

    final modified = Uint8List.fromList(data);
    modified[recordOffset + 8] = (experience >> 16) & 0xff;
    modified[recordOffset + 9] = (experience >> 8) & 0xff;
    modified[recordOffset + 10] = experience & 0xff;
    modified[recordOffset + 31] = level;
    return modified;
  }

  int boxExperience(int boxIndex, int slotIndex) {
    final offset = _boxRecordOffset(boxIndex, slotIndex) + 8;
    return (data[offset] << 16) | (data[offset + 1] << 8) | data[offset + 2];
  }

  Uint8List withBoxTraining(
    int boxIndex,
    int slotIndex, {
    required int attackDv,
    required int defenseDv,
    required int speedDv,
    required int specialDv,
    required int hp,
    required int attack,
    required int defense,
    required int speed,
    required int special,
  }) {
    for (final dv in [attackDv, defenseDv, speedDv, specialDv]) {
      if (dv < 0 || dv > 15) throw RangeError.range(dv, 0, 15, 'DV');
    }
    for (final value in [hp, attack, defense, speed, special]) {
      if (value < 0 || value > 65535) {
        throw RangeError.range(value, 0, 65535, 'Experiencia de esfuerzo');
      }
    }
    final modified = Uint8List.fromList(data);
    final recordOffset = _boxRecordOffset(boxIndex, slotIndex);
    modified[recordOffset + 21] = (attackDv << 4) | defenseDv;
    modified[recordOffset + 22] = (speedDv << 4) | specialDv;
    final effortOffset = recordOffset + 11;
    for (var i = 0; i < 5; i++) {
      _writeWord(
        modified,
        effortOffset + i * 2,
        [hp, attack, defense, speed, special][i],
      );
    }
    return modified;
  }

  int _boxRecordOffset(int boxIndex, int slotIndex) {
    final mon = CrystalPcReader(data).readBox(boxIndex);
    RangeError.checkValidIndex(slotIndex, mon);
    if (mon[slotIndex].isEgg) {
      throw const FormatException('Los huevos no se pueden editar.');
    }
    return CrystalPcReader.boxRecordOffset(boxIndex, slotIndex);
  }

  int partyLevel(int index) {
    _checkPartyIndex(index);
    return data[0x286D + index * 48 + 31];
  }

  int partyExperience(int index) {
    _checkPartyIndex(index);
    final offset = 0x286D + index * 48 + 8;
    return (data[offset] << 16) | (data[offset + 1] << 8) | data[offset + 2];
  }

  /// Sets the party level, adjusts experience to the matching curve, and
  /// recalculates stored stats while preserving the current missing HP.
  Uint8List withPartyLevel(int index, int level) {
    _checkPartyIndex(index);
    if (level < 1 || level > 100) {
      throw RangeError.range(level, 1, 100, 'level');
    }

    final recordOffset = 0x286D + index * 48;
    final speciesId = data[recordOffset];
    final oldLevel = data[recordOffset + 31];
    if (oldLevel < 1 || oldLevel > 100) {
      throw const FormatException('Nivel actual inválido.');
    }
    final oldMinimum = CrystalExperience.forLevel(speciesId, oldLevel);
    final oldMaximum = oldLevel == 100
        ? oldMinimum + 1
        : CrystalExperience.forLevel(speciesId, oldLevel + 1);
    final oldProgress = (partyExperience(index) - oldMinimum)
        .clamp(0, oldMaximum - oldMinimum - 1)
        .toInt();
    final newMinimum = CrystalExperience.forLevel(speciesId, level);
    final newMaximum = level == 100
        ? newMinimum + 1
        : CrystalExperience.forLevel(speciesId, level + 1);
    final newProgress =
        oldProgress * (newMaximum - newMinimum) ~/ (oldMaximum - oldMinimum);
    final experience = newMinimum + newProgress;

    final modified = Uint8List.fromList(data);
    modified[recordOffset + 8] = (experience >> 16) & 0xff;
    modified[recordOffset + 9] = (experience >> 8) & 0xff;
    modified[recordOffset + 10] = experience & 0xff;
    modified[recordOffset + 31] = level;

    final oldMaxHp = _readWord(data, recordOffset + 36);
    final oldCurrentHp = _readWord(data, recordOffset + 34);
    final stats = CrystalStats.fromBox(modified, recordOffset);
    final values = [
      stats.hp,
      stats.attack,
      stats.defense,
      stats.speed,
      stats.specialAttack,
      stats.specialDefense,
    ];
    for (var i = 0; i < values.length; i++) {
      _writeWord(modified, recordOffset + 36 + i * 2, values[i]);
    }
    final currentHp = oldCurrentHp == 0
        ? 0
        : (oldCurrentHp + stats.hp - oldMaxHp).clamp(1, stats.hp).toInt();
    _writeWord(modified, recordOffset + 34, currentHp);
    return modified;
  }

  int partyFriendship(int index) {
    if (index < 0 || index >= partyCount) {
      throw RangeError.index(index, List.filled(partyCount, null));
    }

    final offset = 0x286D + (index * 48) + 27;
    return data[offset];
  }

  int partyPokerusStatus(int index) {
    _checkPartyIndex(index);
    return data[0x286D + index * 48 + 28];
  }

  Uint8List withPartyPokerusStatus(int index, int status) {
    _checkPartyIndex(index);
    if (status < 0 || status > 255 || (status & 15) > 4) {
      throw RangeError.range(status, 0, 0xf4, 'Pokérus');
    }
    final modified = Uint8List.fromList(data);
    modified[0x286D + index * 48 + 28] = status;
    return modified;
  }

  Map<String, int> partyStatExperience(int index) {
    _checkPartyIndex(index);
    final offset = 0x286D + (index * 48) + 11;
    return {
      'hp': _readWord(data, offset),
      'attack': _readWord(data, offset + 2),
      'defense': _readWord(data, offset + 4),
      'speed': _readWord(data, offset + 6),
      'special': _readWord(data, offset + 8),
    };
  }

  Map<String, int> partyDvs(int index) {
    _checkPartyIndex(index);
    final offset = 0x286D + index * 48 + 21;
    return {
      'attack': data[offset] >> 4,
      'defense': data[offset] & 15,
      'speed': data[offset + 1] >> 4,
      'special': data[offset + 1] & 15,
    };
  }

  Uint8List withPartyTraining(
    int index, {
    required int attackDv,
    required int defenseDv,
    required int speedDv,
    required int specialDv,
    required int hp,
    required int attack,
    required int defense,
    required int speed,
    required int special,
  }) {
    _checkPartyIndex(index);
    for (final dv in [attackDv, defenseDv, speedDv, specialDv]) {
      if (dv < 0 || dv > 15) throw RangeError.range(dv, 0, 15, 'DV');
    }
    for (final value in [hp, attack, defense, speed, special]) {
      if (value < 0 || value > 65535) {
        throw RangeError.range(value, 0, 65535, 'Experiencia de esfuerzo');
      }
    }

    final modified = Uint8List.fromList(data);
    final recordOffset = 0x286D + index * 48;
    final dvOffset = recordOffset + 21;
    modified[dvOffset] = (attackDv << 4) | defenseDv;
    modified[dvOffset + 1] = (speedDv << 4) | specialDv;

    final effortOffset = recordOffset + 11;
    for (var i = 0; i < 5; i++) {
      _writeWord(
        modified,
        effortOffset + i * 2,
        [hp, attack, defense, speed, special][i],
      );
    }

    // Recalcula las estadísticas guardadas y conserva el daño actual de PS.
    final oldMaxHp = _readWord(data, recordOffset + 36);
    final oldCurrentHp = _readWord(data, recordOffset + 34);
    final stats = CrystalStats.fromBox(modified, recordOffset);
    final values = [
      stats.hp,
      stats.attack,
      stats.defense,
      stats.speed,
      stats.specialAttack,
      stats.specialDefense,
    ];
    for (var i = 0; i < values.length; i++) {
      _writeWord(modified, recordOffset + 36 + i * 2, values[i]);
    }

    final currentHp = oldCurrentHp == 0
        ? 0
        : (oldCurrentHp + stats.hp - oldMaxHp).clamp(1, stats.hp).toInt();
    _writeWord(modified, recordOffset + 34, currentHp);
    return modified;
  }

  void _checkPartyIndex(int index) {
    if (index < 0 || index >= partyCount) {
      throw RangeError.index(index, List.filled(partyCount, null));
    }
  }

  static int _readWord(Uint8List bytes, int offset) =>
      (bytes[offset] << 8) | bytes[offset + 1];

  static void _writeWord(Uint8List bytes, int offset, int value) {
    bytes[offset] = (value >> 8) & 0xff;
    bytes[offset + 1] = value & 0xff;
  }

  Uint8List withPartyFriendship(int index, int friendship) {
    if (index < 0 || index >= partyCount) {
      throw RangeError.index(index, List.filled(partyCount, null));
    }

    if (friendship < 0 || friendship > 255) {
      throw RangeError.range(friendship, 0, 255);
    }

    final modified = Uint8List.fromList(data);
    final offset = 0x286D + (index * 48) + 27;

    modified[offset] = friendship;

    return modified;
  }
}
