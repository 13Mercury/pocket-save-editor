import 'package:flutter/material.dart';

import '../games/crystal/crystal_catalog.dart';
import '../games/crystal/crystal_move_battle_info.dart';
import '../games/crystal/crystal_move_compatibility.dart';

class CrystalMovePickerSheet extends StatefulWidget {
  final int speciesId;
  final int selectedMoveId;

  const CrystalMovePickerSheet({
    super.key,
    required this.speciesId,
    required this.selectedMoveId,
  });

  @override
  State<CrystalMovePickerSheet> createState() => _CrystalMovePickerSheetState();
}

class _CrystalMovePickerSheetState extends State<CrystalMovePickerSheet> {
  final TextEditingController searchController = TextEditingController();
  int selectedType = -1;
  String selectedCategory = 'Todos';

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  List<_PickerEntry> get entries {
    final query = _normalize(searchController.text);
    final result = <_PickerEntry>[];
    if (query.isEmpty || _normalize('Sin movimiento').contains(query)) {
      result.add(const _PickerEntry.move(0));
    }
    for (final group in crystalMovePickerGroups(widget.speciesId)) {
      final matches = group.moveIds.where((id) {
        final info = crystalMoves[id]!;
        final battle = crystalMoveBattleInfo[id];
        final category = crystalMoveDamageCategory(id, info.typeId);
        return _normalize(info.name).contains(query) &&
            (selectedType == -1 || selectedType == info.typeId) &&
            (selectedCategory == 'Todos' || selectedCategory == category) &&
            battle != null;
      }).toList();
      if (matches.isEmpty) continue;
      result.add(_PickerEntry.header(group.label));
      result.addAll(
        matches.map(
          (id) => _PickerEntry.move(
            id,
            level: group.levels[id],
            learnedBySpeciesId: group.learnedBySpecies[id],
          ),
        ),
      );
    }
    return result;
  }

  String _normalize(String value) =>
      value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

  @override
  Widget build(BuildContext context) {
    final availableTypes = crystalTypeNames.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    final filteredEntries = entries;
    return SafeArea(
      top: false,
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.88,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Elegir movimiento',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Cerrar',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              TextField(
                key: const Key('move-picker-search'),
                controller: searchController,
                autofocus: true,
                onTapOutside: (_) =>
                    FocusManager.instance.primaryFocus?.unfocus(),
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: 'Buscar movimiento',
                  suffixIcon: searchController.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Limpiar búsqueda',
                          onPressed: () {
                            searchController.clear();
                            setState(() {});
                          },
                          icon: const Icon(Icons.clear),
                        ),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text('Tipo'),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      key: const Key('move-picker-type-filter'),
                      initialValue: selectedType,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: -1,
                          child: Text('Todos los tipos'),
                        ),
                        for (final entry in availableTypes)
                          DropdownMenuItem(
                            value: entry.key,
                            child: Text(entry.value),
                          ),
                      ],
                      onChanged: (value) => setState(() {
                        selectedType = value ?? -1;
                      }),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final category in [
                      'Todos',
                      'Físico',
                      'Especial',
                      'Estado',
                    ])
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          key: Key('move-category-${category.toLowerCase()}'),
                          label: Text(category),
                          selected: selectedCategory == category,
                          onSelected: (_) => setState(() {
                            selectedCategory = category;
                          }),
                        ),
                      ),
                  ],
                ),
              ),
              const Divider(height: 8),
              Expanded(
                child: filteredEntries.isEmpty
                    ? const Center(
                        child: Text('No hay movimientos con esos filtros.'),
                      )
                    : ListView.builder(
                        key: const Key('move-picker-list'),
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        itemCount: filteredEntries.length,
                        itemBuilder: (context, index) {
                          final entry = filteredEntries[index];
                          if (entry.groupTitle != null) {
                            return Padding(
                              padding: const EdgeInsets.fromLTRB(8, 12, 8, 4),
                              child: Text(
                                entry.groupTitle!,
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            );
                          }
                          return _moveTile(entry);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _moveTile(_PickerEntry entry) {
    final moveId = entry.moveId!;
    if (moveId == 0) {
      return ListTile(
        key: const Key('move-picker-item-0'),
        leading: const CircleAvatar(child: Icon(Icons.remove)),
        title: const Text('Sin movimiento'),
        selected: widget.selectedMoveId == 0,
        trailing: widget.selectedMoveId == 0 ? const Icon(Icons.check) : null,
        onTap: () => Navigator.pop(context, 0),
      );
    }
    final move = crystalMoves[moveId]!;
    final battle = crystalMoveBattleInfo[moveId]!;
    final category = crystalMoveDamageCategory(moveId, move.typeId);
    final color = Color(crystalTypeColorValue(move.typeId));
    final level = entry.level;
    final learnedBySpeciesId = entry.learnedBySpeciesId;
    return ListTile(
      key: Key('move-picker-item-$moveId'),
      title: Text(move.name),
      selected: widget.selectedMoveId == moveId,
      trailing: widget.selectedMoveId == moveId
          ? const Icon(Icons.check)
          : null,
      subtitle: Wrap(
        spacing: 6,
        runSpacing: 0,
        children: [
          if (level != null && learnedBySpeciesId != null)
            _detailTag(
              crystalMoveLevelDescription(
                speciesId: widget.speciesId,
                level: level,
                learnedBySpeciesId: learnedBySpeciesId,
              ),
            ),
          _detailTag(crystalTypeNames[move.typeId] ?? '???', color: color),
          _detailTag(category),
          _detailTag(battle.power == 0 ? 'Potencia —' : 'Pot. ${battle.power}'),
          _detailTag(
            battle.accuracy == 0 ? 'No falla' : 'Prec. ${battle.accuracy}%',
          ),
        ],
      ),
      onTap: () => Navigator.pop(context, moveId),
    );
  }

  Widget _detailTag(String text, {Color? color}) => Padding(
    padding: const EdgeInsets.only(top: 4),
    child: DecoratedBox(
      decoration: BoxDecoration(
        color:
            color?.withValues(alpha: 0.15) ??
            Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 11,
            color: color,
            fontWeight: color == null ? FontWeight.normal : FontWeight.w600,
          ),
        ),
      ),
    ),
  );
}

class _PickerEntry {
  final String? groupTitle;
  final int? moveId;
  final int? level;
  final int? learnedBySpeciesId;

  const _PickerEntry.header(this.groupTitle)
    : moveId = null,
      level = null,
      learnedBySpeciesId = null;

  const _PickerEntry.move(this.moveId, {this.level, this.learnedBySpeciesId})
    : groupTitle = null;
}
