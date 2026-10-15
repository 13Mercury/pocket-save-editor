import 'package:flutter/material.dart';

import '../games/crystal/crystal_pc_reader.dart';
import '../games/crystal/crystal_reader.dart';
import '../games/crystal/crystal_pokemon_moves.dart';
import 'pokemon_detail_screen.dart';
import 'pokemon_edit_screen.dart';

class PcPokemonDetailScreen extends StatefulWidget {
  final CrystalBoxPokemon? pokemon;
  final CrystalReader? reader;
  final int boxNumber;
  final int slotNumber;
  final Future<CrystalReader?> Function(
    int boxIndex,
    int slotIndex,
    PokemonEditResult result,
  )?
  onSave;

  const PcPokemonDetailScreen({
    super.key,
    this.pokemon,
    this.reader,
    required this.boxNumber,
    required this.slotNumber,
    this.onSave,
  });

  @override
  State<PcPokemonDetailScreen> createState() => _PcPokemonDetailScreenState();
}

class _PcPokemonDetailScreenState extends State<PcPokemonDetailScreen> {
  CrystalReader? reader;
  bool editing = false;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    reader = widget.reader;
  }

  CrystalBoxPokemon get pokemon => reader == null
      ? widget.pokemon!
      : CrystalPcReader(reader!.data).readBox(widget.boxNumber - 1)[
          widget.slotNumber - 1
        ];

  Future<void> save(PokemonEditResult result) async {
    final callback = widget.onSave;
    if (callback == null || saving) return;
    setState(() => saving = true);
    try {
      final updated = await callback(
        widget.boxNumber - 1,
        widget.slotNumber - 1,
        result,
      );
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
    final mon = pokemon;
    final currentReader = reader;
    if (editing && currentReader != null && !mon.isEgg) {
      final boxIndex = widget.boxNumber - 1;
      final slotIndex = widget.slotNumber - 1;
      final effort = currentReader.boxStatExperience(boxIndex, slotIndex);
      final dvs = currentReader.boxDvs(boxIndex, slotIndex);
      final moves = readCrystalMoves(
        currentReader.data,
        CrystalPcReader.boxRecordOffset(boxIndex, slotIndex),
      );
      return PokemonEditScreen(
        key: ValueKey(
          'pc-editor-$boxIndex-$slotIndex-${currentReader.boxNickname(boxIndex, slotIndex)}',
        ),
        nickname: currentReader.boxNickname(boxIndex, slotIndex),
        friendship: currentReader.boxFriendship(boxIndex, slotIndex),
        pokerusStatus: currentReader.boxPokerusStatus(boxIndex, slotIndex),
        heldItemId: currentReader.boxHeldItemId(boxIndex, slotIndex),
        speciesId: mon.speciesId,
        level: mon.level,
        hpStatExp: effort['hp']!,
        attackStatExp: effort['attack']!,
        defenseStatExp: effort['defense']!,
        speedStatExp: effort['speed']!,
        specialStatExp: effort['special']!,
        attackDv: dvs['attack']!,
        defenseDv: dvs['defense']!,
        speedDv: dvs['speed']!,
        specialDv: dvs['special']!,
        moves: moves,
        onCancel: () => setState(() => editing = false),
        onSave: save,
      );
    }
    return PokemonDetailScreen(
      pokemon: mon,
      location: 'Caja ${widget.boxNumber} · Posición ${widget.slotNumber}',
      onEdit: widget.onSave == null || mon.isEgg
          ? null
          : () => setState(() => editing = true),
    );
  }
}
