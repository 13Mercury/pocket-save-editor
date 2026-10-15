import 'dart:typed_data';

import '../../core/pokemon_text_decoder.dart';
import 'crystal_stats.dart';
import 'crystal_pokemon_moves.dart';
import 'crystal_dv_properties.dart';

class CrystalBoxPokemon {
  final int speciesId;
  final String nickname;
  final int level;
  final int friendship;
  final bool isEgg;
  final CrystalStats? stats;
  final List<CrystalMoveSlot> moves;
  final bool isShiny;
  final String? gender;
  final int pokerusStatus;
  final int heldItemId;

  const CrystalBoxPokemon({
    required this.speciesId,
    required this.nickname,
    required this.level,
    required this.friendship,
    required this.isEgg,
    required this.stats,
    this.moves = const [],
    this.isShiny = false,
    this.gender,
    this.pokerusStatus = 0,
    this.heldItemId = 0,
  });
}

// International Crystal layout; Japanese saves use a different box format.
// References: pret/pokecrystal macros/ram.asm and PKHeX.Core/Saves/SAV2.cs.
// Only the stored boxes are read, never the potentially stale active-box copy.
class CrystalPcReader {
  final Uint8List data;
  CrystalPcReader(this.data);
  static const boxCount = 14;
  static const capacity = 20;

  static int boxStartOffset(int index) {
    RangeError.checkValidIndex(index, List.filled(boxCount, null));
    return (index < 7 ? 0x4000 : 0x6000) + (index % 7) * 0x450;
  }

  static int boxRecordOffset(int boxIndex, int slotIndex) {
    RangeError.checkValidIndex(slotIndex, List.filled(capacity, null));
    return boxStartOffset(boxIndex) + 22 + slotIndex * 32;
  }

  static int boxNicknameOffset(int boxIndex, int slotIndex) {
    RangeError.checkValidIndex(slotIndex, List.filled(capacity, null));
    return boxStartOffset(boxIndex) + 882 + slotIndex * 11;
  }

  List<CrystalBoxPokemon> readBox(int index) {
    if (data.length != 32768) {
      throw const FormatException('La partida debe tener 32768 bytes.');
    }
    final offset = boxStartOffset(index);
    final count = data[offset];
    if (count > capacity || data[offset + count + 1] != 0xff) {
      throw FormatException(
        'No se pudo leer la caja ${index + 1}: datos inválidos.',
      );
    }
    return List.unmodifiable(
      List.generate(count, (slot) {
        final record = offset + 22 + slot * 32;
        final species = data[record];
        final marker = data[offset + slot + 1];
        final isEgg = marker == 0xfd;
        if (species < 1 || species > 251 || (!isEgg && marker != species)) {
          throw FormatException(
            'Pokémon inválido en caja ${index + 1}, posición ${slot + 1}.',
          );
        }
        final nickname = offset + 882 + slot * 11;
        return CrystalBoxPokemon(
          speciesId: species,
          nickname: PokemonTextDecoder.decode(
            data.sublist(nickname, nickname + 11),
          ),
          level: data[record + 31],
          friendship: data[record + 27],
          isEgg: isEgg,
          stats: isEgg ? null : CrystalStats.fromBox(data, record),
          moves: isEgg ? const [] : readCrystalMoves(data, record),
          isShiny:
              !isEgg &&
              crystalIsShinyFromDvs(
                data[record + 21] >> 4,
                data[record + 21] & 15,
                data[record + 22] >> 4,
                data[record + 22] & 15,
              ),
          gender: crystalGenderForDvs(
            species,
            data[record + 21] >> 4,
            data[record + 22] >> 4,
          ),
          pokerusStatus: data[record + 28],
          heldItemId: data[record + 1],
        );
      }),
    );
  }
}
