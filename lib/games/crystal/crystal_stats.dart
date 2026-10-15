import 'dart:math' as math;
import 'dart:typed_data';

import 'crystal_base_stats.dart';

class CrystalStats {
  final int hp, attack, defense, speed, specialAttack, specialDefense;
  const CrystalStats(
    this.hp,
    this.attack,
    this.defense,
    this.speed,
    this.specialAttack,
    this.specialDefense,
  );

  static int _word(Uint8List data, int offset) =>
      (data[offset] << 8) | data[offset + 1];

  factory CrystalStats.fromParty(Uint8List data, int index) {
    final count = data[0x2865];
    if (count > 6) throw const FormatException('Equipo inválido.');
    RangeError.checkValidIndex(index, List.filled(count, null));
    final offset = 0x286d + index * 48 + 36;
    return CrystalStats(
      _word(data, offset),
      _word(data, offset + 2),
      _word(data, offset + 4),
      _word(data, offset + 6),
      _word(data, offset + 8),
      _word(data, offset + 10),
    );
  }

  // Generation II: ceiling square root, capped at 255, then divided by 4.
  // Special Attack and Special Defense share their DV and stat experience.
  factory CrystalStats.fromBox(Uint8List data, int offset) {
    final species = data[offset];
    final base = crystalBaseStats[species];
    if (base == null) throw const FormatException('Especie inválida.');
    final level = data[offset + 31];
    if (level < 1 || level > 100) {
      throw const FormatException('Nivel inválido.');
    }
    final atk = data[offset + 21] >> 4;
    final def = data[offset + 21] & 15;
    final speed = data[offset + 22] >> 4;
    final special = data[offset + 22] & 15;
    return CrystalStats.fromValues(
      speciesId: species,
      level: level,
      attackDv: atk,
      defenseDv: def,
      speedDv: speed,
      specialDv: special,
      hpStatExp: _word(data, offset + 11),
      attackStatExp: _word(data, offset + 13),
      defenseStatExp: _word(data, offset + 15),
      speedStatExp: _word(data, offset + 17),
      specialStatExp: _word(data, offset + 19),
    );
  }

  factory CrystalStats.fromValues({
    required int speciesId,
    required int level,
    required int attackDv,
    required int defenseDv,
    required int speedDv,
    required int specialDv,
    required int hpStatExp,
    required int attackStatExp,
    required int defenseStatExp,
    required int speedStatExp,
    required int specialStatExp,
  }) {
    final base = crystalBaseStats[speciesId];
    if (base == null) throw const FormatException('Especie inválida.');
    if (level < 1 || level > 100) {
      throw const FormatException('Nivel inválido.');
    }
    final atk = attackDv;
    final def = defenseDv;
    final speed = speedDv;
    final special = specialDv;
    final hp =
        ((atk & 1) << 3) |
        ((def & 1) << 2) |
        ((speed & 1) << 1) |
        (special & 1);
    final effortValues = <int, int>{
      11: hpStatExp,
      13: attackStatExp,
      15: defenseStatExp,
      17: speedStatExp,
      19: specialStatExp,
    };
    int stat(int i, int dv, int effortOffset) {
      final effort =
          math.min(255, math.sqrt(effortValues[effortOffset]!).ceil()) ~/ 4;
      return ((2 * (base[i] + dv) + effort) * level) ~/ 100 + 5;
    }

    return CrystalStats(
      stat(0, hp, 11) + level + 5,
      stat(1, atk, 13),
      stat(2, def, 15),
      stat(3, speed, 17),
      stat(4, special, 19),
      stat(5, special, 19),
    );
  }

  String get summary =>
      'PS $hp · Atq $attack · Def $defense\n'
      'At. Esp. $specialAttack · Def. Esp. $specialDefense · Vel $speed';
}
