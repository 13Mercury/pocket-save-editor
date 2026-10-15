import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/pokemon_species.dart';
import '../games/crystal/crystal_catalog.dart';
import '../games/crystal/crystal_dv_properties.dart';
import '../games/crystal/crystal_gender_ratios.dart';
import '../games/crystal/crystal_move_compatibility.dart';
import '../games/crystal/crystal_move_battle_info.dart';
import '../games/crystal/crystal_pokemon_moves.dart';
import '../games/crystal/crystal_stats.dart';
import '../games/crystal/crystal_held_items.dart';
import '../widgets/crystal_move_picker.dart';
import '../widgets/pokemon_sprite.dart';
import '../widgets/item_sprite.dart';

class PokemonEditResult {
  final String nickname;
  final int friendship;
  final int pokerusStatus;
  final int heldItemId;
  final int hpStatExp;
  final int level;
  final int attackStatExp;
  final int defenseStatExp;
  final int speedStatExp;
  final int specialStatExp;
  final int attackDv;
  final int defenseDv;
  final int speedDv;
  final int specialDv;
  final List<CrystalMoveSlot> moves;

  const PokemonEditResult({
    required this.nickname,
    required this.friendship,
    required this.pokerusStatus,
    required this.heldItemId,
    required this.level,
    required this.hpStatExp,
    required this.attackStatExp,
    required this.defenseStatExp,
    required this.speedStatExp,
    required this.specialStatExp,
    required this.attackDv,
    required this.defenseDv,
    required this.speedDv,
    required this.specialDv,
    required this.moves,
  });
}

class PokemonEditScreen extends StatefulWidget {
  final String nickname;
  final int friendship;
  final int pokerusStatus;
  final int heldItemId;
  final int speciesId;
  final int level;
  final int hpStatExp;
  final int attackStatExp;
  final int defenseStatExp;
  final int speedStatExp;
  final int specialStatExp;
  final int attackDv;
  final int defenseDv;
  final int speedDv;
  final int specialDv;
  final List<CrystalMoveSlot> moves;
  final ValueChanged<PokemonEditResult> onSave;
  final VoidCallback onCancel;

  const PokemonEditScreen({
    super.key,
    required this.nickname,
    required this.friendship,
    required this.pokerusStatus,
    required this.heldItemId,
    required this.speciesId,
    required this.level,
    required this.hpStatExp,
    required this.attackStatExp,
    required this.defenseStatExp,
    required this.speedStatExp,
    required this.specialStatExp,
    required this.attackDv,
    required this.defenseDv,
    required this.speedDv,
    required this.specialDv,
    required this.moves,
    required this.onSave,
    required this.onCancel,
  });

  @override
  State<PokemonEditScreen> createState() => _PokemonEditScreenState();
}

class _PokemonEditScreenState extends State<PokemonEditScreen> {
  late final TextEditingController nicknameController;
  late final TextEditingController hpStatExpController;
  late final TextEditingController attackStatExpController;
  late final TextEditingController defenseStatExpController;
  late final TextEditingController speedStatExpController;
  late final TextEditingController specialStatExpController;
  late double friendship;
  late int pokerusStatus;
  late int heldItemId;
  late double level;
  late double attackDv;
  late double defenseDv;
  late double speedDv;
  late double specialDv;
  late List<CrystalMoveSlot> moves;

  @override
  void initState() {
    super.initState();
    nicknameController = TextEditingController(text: widget.nickname);
    friendship = widget.friendship.toDouble();
    pokerusStatus = widget.pokerusStatus;
    heldItemId = widget.heldItemId;
    level = widget.level.toDouble();
    attackDv = widget.attackDv.toDouble();
    defenseDv = widget.defenseDv.toDouble();
    speedDv = widget.speedDv.toDouble();
    specialDv = widget.specialDv.toDouble();
    moves = List.of(widget.moves);
    hpStatExpController = TextEditingController(text: '${widget.hpStatExp}');
    attackStatExpController = TextEditingController(
      text: '${widget.attackStatExp}',
    );
    defenseStatExpController = TextEditingController(
      text: '${widget.defenseStatExp}',
    );
    speedStatExpController = TextEditingController(
      text: '${widget.speedStatExp}',
    );
    specialStatExpController = TextEditingController(
      text: '${widget.specialStatExp}',
    );
  }

  @override
  void dispose() {
    nicknameController.dispose();
    hpStatExpController.dispose();
    attackStatExpController.dispose();
    defenseStatExpController.dispose();
    speedStatExpController.dispose();
    specialStatExpController.dispose();
    super.dispose();
  }

  void saveChanges() {
    final nickname = nicknameController.text.trim();
    if (nickname.isEmpty || nickname.length > 10) {
      _showError('El apodo debe tener entre 1 y 10 caracteres.');
      return;
    }
    if (!RegExp(r'^[A-Za-z0-9 -]+$').hasMatch(nickname)) {
      _showError('El apodo contiene caracteres no compatibles.');
      return;
    }

    final effortValues = [
      hpStatExpController,
      attackStatExpController,
      defenseStatExpController,
      speedStatExpController,
      specialStatExpController,
    ].map((controller) => int.tryParse(controller.text)).toList();
    if (effortValues.any(
      (value) => value == null || value < 0 || value > 65535,
    )) {
      _showError('Cada valor debe estar entre 0 y 65535.');
      return;
    }

    widget.onSave(
      PokemonEditResult(
        nickname: nickname,
        friendship: friendship.round(),
        pokerusStatus: pokerusStatus,
        heldItemId: heldItemId,
        level: level.round(),
        hpStatExp: effortValues[0]!,
        attackStatExp: effortValues[1]!,
        defenseStatExp: effortValues[2]!,
        speedStatExp: effortValues[3]!,
        specialStatExp: effortValues[4]!,
        attackDv: attackDv.round(),
        defenseDv: defenseDv.round(),
        speedDv: speedDv.round(),
        specialDv: specialDv.round(),
        moves: List.unmodifiable(moves),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  int _intValue(TextEditingController controller, int fallback) =>
      int.tryParse(controller.text) ?? fallback;

  CrystalStats? get previewStats {
    try {
      return CrystalStats.fromValues(
        speciesId: widget.speciesId,
        level: level.round(),
        attackDv: attackDv.round(),
        defenseDv: defenseDv.round(),
        speedDv: speedDv.round(),
        specialDv: specialDv.round(),
        hpStatExp: _intValue(hpStatExpController, widget.hpStatExp),
        attackStatExp: _intValue(attackStatExpController, widget.attackStatExp),
        defenseStatExp: _intValue(
          defenseStatExpController,
          widget.defenseStatExp,
        ),
        speedStatExp: _intValue(speedStatExpController, widget.speedStatExp),
        specialStatExp: _intValue(
          specialStatExpController,
          widget.specialStatExp,
        ),
      );
    } on FormatException {
      return null;
    }
  }

  void _updateMove(int slot, CrystalMoveSlot move) {
    setState(() => moves[slot] = move);
  }

  Future<void> _chooseHeldItem() async {
    final selected = await showCrystalHeldItemPicker(
      context,
      currentItemId: heldItemId,
    );
    if (selected != null && mounted) setState(() => heldItemId = selected);
  }

  void _setGender(String target) {
    final attack = crystalAttackDvForGender(
      speciesId: widget.speciesId,
      gender: target,
      speedDv: speedDv.round(),
      currentAttackDv: attackDv.round(),
      keepShiny: crystalIsShinyFromDvs(
        attackDv.round(),
        defenseDv.round(),
        speedDv.round(),
        specialDv.round(),
      ),
    );
    if (attack == null) {
      _showError(
        'Esa combinación de sexo y variocolor no es posible con los DVs de Gen 2.',
      );
      return;
    }
    setState(() => attackDv = attack.toDouble());
  }

  void _setShiny(bool enabled) {
    final previousGender = crystalGenderForDvs(
      widget.speciesId,
      attackDv.round(),
      speedDv.round(),
    );
    String? updatedGender;
    setState(() {
      if (enabled) {
        final currentGender = crystalGenderForDvs(
          widget.speciesId,
          attackDv.round(),
          speedDv.round(),
        );
        final compatibleAttack = currentGender == null
            ? null
            : crystalAttackDvForGender(
                speciesId: widget.speciesId,
                gender: currentGender,
                speedDv: 10,
                currentAttackDv: attackDv.round(),
                keepShiny: true,
              );
        attackDv =
            (compatibleAttack ??
                    const [2, 3, 6, 7, 10, 11, 14, 15].reduce(_closestAttackDv))
                .toDouble();
        defenseDv = 10;
        speedDv = 10;
        specialDv = 10;
      } else if (crystalIsShinyFromDvs(
        attackDv.round(),
        defenseDv.round(),
        speedDv.round(),
        specialDv.round(),
      )) {
        specialDv = 9;
      }
      updatedGender = crystalGenderForDvs(
        widget.speciesId,
        attackDv.round(),
        speedDv.round(),
      );
    });
    if (enabled &&
        previousGender != null &&
        updatedGender != null &&
        previousGender != updatedGender) {
      _showError(
        'El sexo cambió a $updatedGender por la combinación de DVs variocolor de Gen 2.',
      );
    }
  }

  int _closestAttackDv(int left, int right) =>
      (left - attackDv.round()).abs() <= (right - attackDv.round()).abs()
      ? left
      : right;

  void _setPokerusActive(bool active) {
    final strain = pokerusStatus & 0xf0;
    setState(() {
      if (active) {
        // Four days is the maximum valid active duration in Generation II.
        pokerusStatus = (strain == 0 ? 0x10 : strain) | 0x04;
      } else if ((pokerusStatus & 0x0f) > 0) {
        // Clearing the day counter cures the infection and preserves immunity.
        pokerusStatus = strain == 0 ? 0x10 : strain;
      }
    });
  }

  Future<void> _chooseMove(int slot) async {
    final moveId = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => CrystalMovePickerSheet(
        speciesId: widget.speciesId,
        selectedMoveId: moves[slot].id,
      ),
    );
    if (!mounted || moveId == null) return;
    final selected = crystalMoves[moveId];
    _updateMove(slot, CrystalMoveSlot(moveId, selected?.basePp ?? 0, 0));
  }

  @override
  Widget build(BuildContext context) {
    final gender = crystalGenderForDvs(
      widget.speciesId,
      attackDv.round(),
      speedDv.round(),
    );
    final isShiny = crystalIsShinyFromDvs(
      attackDv.round(),
      defenseDv.round(),
      speedDv.round(),
      specialDv.round(),
    );
    final genderRatio = crystalGenderRatios[widget.speciesId];
    final canChooseGender =
        genderRatio != null && genderRatio > 0 && genderRatio < 99;
    final pokerusDays = pokerusStatus & 0x0f;
    final pokerusStrain = pokerusStatus & 0xf0;
    final pokerusSubtitle = pokerusDays > 0
        ? 'Duplica la experiencia de esfuerzo y puede contagiarlo a otros Pokémon. Quedan $pokerusDays día(s) activo.'
        : pokerusStrain > 0
        ? 'Está curado y ya no contagia; en Gen 2 aún duplica la experiencia de esfuerzo y conserva inmunidad.'
        : 'Actívalo para duplicar la experiencia de esfuerzo obtenida en combate.';
    final stats = previewStats;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: widget.onCancel,
          icon: const Icon(Icons.arrow_back),
        ),
        title: Row(
          children: [
            PokemonSprite(speciesId: widget.speciesId, isShiny: isShiny),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    PokemonSpecies.getName(widget.speciesId),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: nicknameController,
                    builder: (context, value, child) => Text(
                      value.text.isEmpty ? 'Sin apodo' : value.text,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (event) {
          final focusedNode = FocusManager.instance.primaryFocus;
          final renderObject = focusedNode?.context?.findRenderObject();
          if (renderObject is RenderBox && renderObject.hasSize) {
            final fieldBounds =
                renderObject.localToGlobal(Offset.zero) & renderObject.size;
            if (!fieldBounds.contains(event.position)) focusedNode?.unfocus();
          }
        },
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.all(24),
          children: [
            TextField(
              key: const Key('pokemon-nickname'),
              controller: nicknameController,
              maxLength: 10,
              onTapOutside: (_) => FocusScope.of(context).unfocus(),
              decoration: const InputDecoration(
                labelText: 'Apodo',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Nivel: ${level.round()} / 100',
              key: const Key('pokemon-level-value'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Slider(
              key: const Key('pokemon-level-slider'),
              value: level,
              min: 1,
              max: 100,
              divisions: 99,
              label: level.round().toString(),
              onChanged: (value) => setState(() => level = value),
            ),
            const Text(
              'La experiencia se ajustará al nivel y conservará el progreso. Los stats y PS se actualizarán al guardar.',
            ),
            const SizedBox(height: 12),
            Text(
              'Amistad: ${friendship.round()} / 255',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Slider(
              value: friendship,
              min: 0,
              max: 255,
              divisions: 255,
              label: friendship.round().toString(),
              onChanged: (value) => setState(() => friendship = value),
            ),
            SwitchListTile.adaptive(
              key: const Key('pokemon-pokerus-switch'),
              contentPadding: EdgeInsets.zero,
              title: const Text('Pokérus activo'),
              subtitle: Text(pokerusSubtitle),
              value: pokerusDays > 0,
              onChanged: _setPokerusActive,
            ),
            Card(
              child: ListTile(
                key: const Key('pokemon-held-item'),
                leading: heldItemId == 0
                    ? const Icon(Icons.block)
                    : ItemSprite(itemId: heldItemId),
                title: Text(
                  heldItemId == 0 ? 'Sin objeto' : crystalItemName(heldItemId),
                ),
                subtitle: Text(crystalHeldItemDescription(heldItemId)),
                trailing: const Icon(Icons.chevron_right),
                onTap: _chooseHeldItem,
              ),
            ),
            if (friendship >= 220)
              const Text(
                'Amistad suficiente para evolucionar',
                style: TextStyle(color: Colors.green),
              ),
            const SizedBox(height: 24),
            Text('DVs de Gen 2', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            const Text(
              'Son valores propios de esta generación, distintos de los IV. El DV de PS se calcula con los otros cuatro; género y brillo pueden cambiar al modificarlos.',
            ),
            const SizedBox(height: 12),
            SwitchListTile.adaptive(
              key: const Key('pokemon-shiny-switch'),
              contentPadding: EdgeInsets.zero,
              title: const Text('Variocolor'),
              subtitle: const Text(
                'Ajusta los DVs necesarios; puede cambiar el sexo y los stats.',
              ),
              value: isShiny,
              onChanged: _setShiny,
            ),
            OutlinedButton.icon(
              key: const Key('maximize-pokemon-stats'),
              onPressed: () => setState(() {
                attackDv = 15;
                defenseDv = 15;
                speedDv = 15;
                specialDv = 15;
                hpStatExpController.text = '65535';
                attackStatExpController.text = '65535';
                defenseStatExpController.text = '65535';
                speedStatExpController.text = '65535';
                specialStatExpController.text = '65535';
              }),
              icon: const Icon(Icons.trending_up),
              label: const Text('Maximizar stats'),
            ),
            _dvSlider('Ataque', attackDv, (v) => attackDv = v),
            _dvSlider('Defensa', defenseDv, (v) => defenseDv = v),
            _dvSlider('Velocidad', speedDv, (v) => speedDv = v),
            _dvSlider('Especial', specialDv, (v) => specialDv = v),
            if (canChooseGender)
              SegmentedButton<String>(
                key: const Key('pokemon-gender-selector'),
                segments: const [
                  ButtonSegment(value: 'Macho', label: Text('Macho')),
                  ButtonSegment(value: 'Hembra', label: Text('Hembra')),
                ],
                selected: {gender!},
                onSelectionChanged: (selection) => _setGender(selection.first),
              ),
            Wrap(
              spacing: 8,
              children: [
                if (gender != null) Chip(label: Text(gender)),
                Chip(
                  key: const Key('shiny-preview-status'),
                  label: Text(isShiny ? 'Variocolor' : 'Normal'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Vista previa de stats',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            if (stats != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'PS ${stats.hp} · Ataque ${stats.attack} · Defensa ${stats.defense}\n'
                    'Especial ${stats.specialAttack} · Velocidad ${stats.speed}',
                  ),
                ),
              ),
            const SizedBox(height: 12),
            Text(
              'Experiencia de esfuerzo',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            _effortField('PS', hpStatExpController),
            _effortField('Ataque', attackStatExpController),
            _effortField('Defensa', defenseStatExpController),
            _effortField('Velocidad', speedStatExpController),
            _effortField('Especial', specialStatExpController),
            const SizedBox(height: 24),
            Text('Movimientos', style: Theme.of(context).textTheme.titleLarge),
            const Text(
              'Puedes dejar espacios vacíos, cambiar movimientos y ajustar PP Ups y PP actuales.',
            ),
            const SizedBox(height: 8),
            for (var slot = 0; slot < 4; slot++) _moveEditor(slot),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: saveChanges,
              icon: const Icon(Icons.save),
              label: const Text('Guardar cambios'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: widget.onCancel,
              child: const Text('Cancelar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _moveEditor(int slot) {
    final move = moves[slot];
    final info = crystalMoves[move.id];
    final maxPp = move.maxPp ?? 0;
    final currentPp = move.currentPp.clamp(0, maxPp);
    return Card(
      key: Key('move-slot-$slot'),
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Espacio ${slot + 1}',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            OutlinedButton.icon(
              key: Key('move-select-$slot'),
              onPressed: () => _chooseMove(slot),
              icon: const Icon(Icons.search),
              label: Text(
                move.id == 0 ? 'Elegir movimiento' : move.name,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (info != null) ...[
              _moveBattleSummary(move.id, info.typeId),
              if (crystalCanLearnMove(widget.speciesId, move.id) == false)
                const ListTile(
                  key: Key('move-legality-warning'),
                  leading: Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.deepOrange,
                  ),
                  title: Text(
                    'No aparece como aprendible en Cristal para esta especie.',
                  ),
                  subtitle: Text(
                    'Puedes conservarlo o guardarlo de todos modos.',
                  ),
                  dense: true,
                ),
              Row(
                children: [
                  const Expanded(child: Text('PP Ups')),
                  DropdownButton<int>(
                    key: Key('move-ppups-$slot'),
                    value: move.ppUps,
                    items: [
                      for (var value = 0; value <= 3; value++)
                        DropdownMenuItem(value: value, child: Text('$value')),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      final updated = CrystalMoveSlot(
                        move.id,
                        move.currentPp,
                        value,
                      );
                      _updateMove(
                        slot,
                        CrystalMoveSlot(
                          move.id,
                          updated.currentPp.clamp(0, updated.maxPp!),
                          value,
                        ),
                      );
                    },
                  ),
                ],
              ),
              Row(
                children: [
                  const Expanded(child: Text('PP actuales')),
                  IconButton(
                    key: Key('move-pp-minus-$slot'),
                    onPressed: currentPp > 0
                        ? () => _updateMove(
                            slot,
                            CrystalMoveSlot(move.id, currentPp - 1, move.ppUps),
                          )
                        : null,
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  Text('$currentPp / $maxPp', key: Key('move-pp-value-$slot')),
                  IconButton(
                    key: Key('move-pp-plus-$slot'),
                    onPressed: currentPp < maxPp
                        ? () => _updateMove(
                            slot,
                            CrystalMoveSlot(move.id, currentPp + 1, move.ppUps),
                          )
                        : null,
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _moveBattleSummary(int moveId, int typeId) {
    final battle = crystalMoveBattleInfo[moveId];
    if (battle == null) return const SizedBox.shrink();
    final category = crystalMoveDamageCategory(moveId, typeId);
    final color = Color(crystalTypeColorValue(typeId));
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 6,
        runSpacing: 2,
        children: [
          Chip(
            visualDensity: VisualDensity.compact,
            backgroundColor: color.withValues(alpha: 0.18),
            label: Text(
              crystalTypeNames[typeId] ?? 'Tipo desconocido',
              style: TextStyle(color: color, fontWeight: FontWeight.w700),
            ),
          ),
          Chip(
            visualDensity: VisualDensity.compact,
            avatar: Icon(
              category == 'Físico'
                  ? Icons.sports_martial_arts
                  : category == 'Especial'
                  ? Icons.auto_awesome
                  : Icons.shield_outlined,
              size: 16,
            ),
            label: Text(category),
          ),
          Chip(
            visualDensity: VisualDensity.compact,
            label: Text(
              battle.power == 0 ? 'Potencia —' : 'Potencia ${battle.power}',
            ),
          ),
          Chip(
            visualDensity: VisualDensity.compact,
            label: Text(
              battle.accuracy == 0
                  ? 'No falla'
                  : 'Precisión ${battle.accuracy}%',
            ),
          ),
        ],
      ),
    );
  }

  Widget _effortField(String label, TextEditingController controller) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextField(
          controller: controller,
          onTapOutside: (_) => FocusScope.of(context).unfocus(),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            labelText: label,
            helperText: '0–65535',
            border: const OutlineInputBorder(),
          ),
        ),
      );

  Widget _dvSlider(String label, double value, ValueChanged<double> update) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ${value.round()} / 15'),
          Slider(
            value: value,
            min: 0,
            max: 15,
            divisions: 15,
            label: value.round().toString(),
            onChanged: (next) => setState(() => update(next)),
          ),
        ],
      );
}
