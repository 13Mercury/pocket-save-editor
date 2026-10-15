import 'package:flutter/material.dart';

import '../games/crystal/crystal_reader.dart';
import '../games/crystal/crystal_pc_reader.dart';
import '../games/crystal/crystal_stats.dart';
import '../games/crystal/crystal_dv_properties.dart';
import '../games/crystal/crystal_pokemon_moves.dart';
import 'pokemon_detail_screen.dart';
import 'pokemon_edit_screen.dart';

class PartyPokemonDetailScreen extends StatefulWidget {
  final CrystalReader reader;
  final int index;
  final Future<CrystalReader?> Function(PokemonEditResult result) onSave;

  const PartyPokemonDetailScreen({
    super.key,
    required this.reader,
    required this.index,
    required this.onSave,
  });

  @override
  State<PartyPokemonDetailScreen> createState() =>
      _PartyPokemonDetailScreenState();
}

class _PartyPokemonDetailScreenState extends State<PartyPokemonDetailScreen> {
  late CrystalReader reader = widget.reader;
  bool editing = false;
  bool saving = false;

  Future<void> save(PokemonEditResult result) async {
    if (saving) return;
    setState(() => saving = true);
    try {
      final updated = await widget.onSave(result);
      if (mounted && updated != null) {
        setState(() {
          reader = updated;
          editing = false;
        });
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final index = widget.index;
    final offset = 0x286d + index * 48;
    final isEgg = reader.partySpecies[index] == 0xfd;
    final species = reader.data[offset];
    final dvs = reader.partyDvs(index);
    if (editing && !isEgg) {
      final effort = reader.partyStatExperience(index);
      return PokemonEditScreen(
        key: ValueKey('party-editor-$index-${reader.partyNicknames[index]}'),
        nickname: reader.partyNicknames[index],
        friendship: reader.partyFriendship(index),
        pokerusStatus: reader.partyPokerusStatus(index),
        heldItemId: reader.partyHeldItemId(index),
        speciesId: species,
        level: reader.data[offset + 31],
        hpStatExp: effort['hp']!,
        attackStatExp: effort['attack']!,
        defenseStatExp: effort['defense']!,
        speedStatExp: effort['speed']!,
        specialStatExp: effort['special']!,
        attackDv: dvs['attack']!,
        defenseDv: dvs['defense']!,
        speedDv: dvs['speed']!,
        specialDv: dvs['special']!,
        moves: readCrystalMoves(reader.data, offset),
        onCancel: () => setState(() => editing = false),
        onSave: save,
      );
    }
    return PokemonDetailScreen(
      location: 'Equipo · Posición ${index + 1}',
      pokemon: CrystalBoxPokemon(
        speciesId: species,
        nickname: reader.partyNicknames[index],
        level: reader.data[offset + 31],
        friendship: reader.partyFriendship(index),
        isEgg: isEgg,
        stats: isEgg ? null : CrystalStats.fromParty(reader.data, index),
        moves: isEgg ? const [] : readCrystalMoves(reader.data, offset),
        isShiny:
            !isEgg &&
            crystalIsShinyFromDvs(
              dvs['attack']!,
              dvs['defense']!,
              dvs['speed']!,
              dvs['special']!,
            ),
        gender: isEgg
            ? null
            : crystalGenderForDvs(species, dvs['attack']!, dvs['speed']!),
        pokerusStatus: isEgg ? 0 : reader.partyPokerusStatus(index),
        heldItemId: isEgg ? 0 : reader.partyHeldItemId(index),
      ),
      onEdit: isEgg ? null : () => setState(() => editing = true),
    );
  }
}
