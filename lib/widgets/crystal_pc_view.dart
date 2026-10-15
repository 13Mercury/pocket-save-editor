import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../core/pokemon_species.dart';
import '../games/crystal/crystal_pc_reader.dart';
import '../games/crystal/crystal_reader.dart';
import '../screens/pokemon_edit_screen.dart';
import 'pokemon_sprite.dart';
import '../screens/pc_pokemon_detail_screen.dart';

class CrystalPcView extends StatefulWidget {
  final Uint8List data;
  final Future<CrystalReader?> Function(
    int boxIndex,
    int slotIndex,
    PokemonEditResult result,
  )?
  onSave;

  const CrystalPcView({super.key, required this.data, this.onSave});
  @override
  State<CrystalPcView> createState() => _CrystalPcViewState();
}

class _CrystalPcViewState extends State<CrystalPcView> {
  final TextEditingController searchController = TextEditingController();
  int selectedBox = 0;
  int minimumLevel = 0;
  bool onlyShiny = false;
  bool showGrid = true;

  bool get hasFilters =>
      searchController.text.trim().isNotEmpty || onlyShiny || minimumLevel > 0;

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void openPokemon(int boxIndex, int slotIndex) {
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (context) => PcPokemonDetailScreen(
          reader: CrystalReader(widget.data),
          boxNumber: boxIndex + 1,
          slotNumber: slotIndex + 1,
          onSave: widget.onSave,
        ),
      ),
    );
  }

  List<_PcSearchResult> findMatches() {
    final query = searchController.text.trim().toLowerCase();
    final matches = <_PcSearchResult>[];
    final reader = CrystalPcReader(widget.data);
    for (var boxIndex = 0; boxIndex < CrystalPcReader.boxCount; boxIndex++) {
      final box = reader.readBox(boxIndex);
      for (var slotIndex = 0; slotIndex < box.length; slotIndex++) {
        final mon = box[slotIndex];
        if (onlyShiny && !mon.isShiny) continue;
        if (minimumLevel > 0 && (mon.isEgg || mon.level < minimumLevel)) {
          continue;
        }
        final speciesName = mon.isEgg
            ? 'Huevo'
            : PokemonSpecies.getName(mon.speciesId);
        if (query.isNotEmpty &&
            !speciesName.toLowerCase().contains(query) &&
            !mon.nickname.toLowerCase().contains(query)) {
          continue;
        }
        matches.add(_PcSearchResult(boxIndex, slotIndex, mon));
      }
    }
    return matches;
  }

  Widget buildGrid(List<CrystalBoxPokemon> pokemon) {
    final textScale = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 2.0);
    return GridView.builder(
      key: ValueKey('grid-$selectedBox'),
      padding: const EdgeInsets.symmetric(vertical: 6),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisExtent: 116 * textScale,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
      ),
      itemCount: CrystalPcReader.capacity,
      itemBuilder: (context, index) {
        final mon = index < pokemon.length ? pokemon[index] : null;
        if (mon == null) {
          return Semantics(
            label: 'Espacio ${index + 1} vacío',
            child: Card(
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              child: Center(
                child: Text(
                  '${index + 1} · Vacío',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }
        final name = mon.isEgg ? 'Huevo' : mon.nickname;
        return Semantics(
          button: true,
          label: mon.isEgg
              ? 'Huevo, posición ${index + 1}'
              : '${PokemonSpecies.getName(mon.speciesId)}, ${mon.nickname}, nivel ${mon.level}, posición ${index + 1}',
          child: Card(
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => openPokemon(selectedBox, index),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (mon.isEgg)
                      const SizedBox(
                        height: 40,
                        child: Icon(Icons.egg_outlined, size: 30),
                      )
                    else
                      PokemonSprite(speciesId: mon.speciesId, size: 40),
                    const SizedBox(height: 2),
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                    if (!mon.isEgg)
                      Text(
                        'Nv. ${mon.level}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    List<CrystalBoxPokemon> pokemon = [];
    List<_PcSearchResult> matches = [];
    String? error;
    try {
      if (hasFilters) {
        matches = findMatches();
      } else {
        pokemon = CrystalPcReader(widget.data).readBox(selectedBox);
      }
    } on FormatException catch (e) {
      error = e.message;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!hasFilters)
          Row(
            children: [
              IconButton(
                tooltip: 'Caja anterior',
                onPressed: selectedBox > 0
                    ? () => setState(() => selectedBox--)
                    : null,
                icon: const Icon(Icons.chevron_left),
              ),
              Expanded(
                child: DropdownButton<int>(
                  key: const Key('pc-box-selector'),
                  value: selectedBox,
                  isExpanded: true,
                  items: List.generate(
                    CrystalPcReader.boxCount,
                    (i) => DropdownMenuItem(
                      value: i,
                      child: Text('Caja ${i + 1}'),
                    ),
                  ),
                  onChanged: (value) {
                    if (value != null) setState(() => selectedBox = value);
                  },
                ),
              ),
              IconButton(
                tooltip: 'Caja siguiente',
                onPressed: selectedBox < CrystalPcReader.boxCount - 1
                    ? () => setState(() => selectedBox++)
                    : null,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 4),
          child: TextField(
            key: const Key('pc-search'),
            controller: searchController,
            onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: 'Buscar especie o apodo en el PC',
              isDense: true,
              border: const OutlineInputBorder(),
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
            ),
          ),
        ),
        Row(
          children: [
            FilterChip(
              key: const Key('pc-shiny-filter'),
              avatar: const Icon(Icons.auto_awesome, size: 18),
              label: const Text('Variocolor'),
              selected: onlyShiny,
              onSelected: (value) => setState(() => onlyShiny = value),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: DropdownButton<int>(
                key: const Key('pc-level-filter'),
                value: minimumLevel,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(value: 0, child: Text('Todos los niveles')),
                  DropdownMenuItem(value: 25, child: Text('Nivel 25+')),
                  DropdownMenuItem(value: 50, child: Text('Nivel 50+')),
                  DropdownMenuItem(value: 75, child: Text('Nivel 75+')),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => minimumLevel = value);
                },
              ),
            ),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: Text(
                hasFilters
                    ? '${matches.length} resultados en todas las cajas'
                    : 'Caja ${selectedBox + 1} · ${pokemon.length}/20 Pokémon',
              ),
            ),
            if (!hasFilters)
              IconButton(
                tooltip: showGrid ? 'Ver como lista' : 'Ver como cuadrícula',
                icon: Icon(showGrid ? Icons.view_list : Icons.grid_view),
                onPressed: () => setState(() => showGrid = !showGrid),
              ),
          ],
        ),
        if (error == null && !hasFilters && pokemon.isEmpty && showGrid)
          const Text('Esta caja está vacía.'),
        Expanded(
          child: error != null
              ? Center(child: Text(error, textAlign: TextAlign.center))
              : hasFilters
              ? matches.isEmpty
                    ? const Center(child: Text('No hay Pokémon que coincidan.'))
                    : ListView.builder(
                        key: const ValueKey('pc-search-results'),
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        itemCount: matches.length,
                        itemBuilder: (context, index) {
                          final result = matches[index];
                          final mon = result.pokemon;
                          return Card(
                            child: ListTile(
                              onTap: () => openPokemon(
                                result.boxIndex,
                                result.slotIndex,
                              ),
                              leading: mon.isEgg
                                  ? const SizedBox(
                                      width: 56,
                                      child: Icon(Icons.egg_outlined),
                                    )
                                  : PokemonSprite(
                                      speciesId: mon.speciesId,
                                      isShiny: mon.isShiny,
                                    ),
                              title: Text(
                                mon.isEgg
                                    ? 'Huevo'
                                    : '${PokemonSpecies.getName(mon.speciesId)} — ${mon.nickname}',
                              ),
                              subtitle: Text(
                                mon.isEgg
                                    ? 'Caja ${result.boxIndex + 1} · Posición ${result.slotIndex + 1}'
                                    : 'Caja ${result.boxIndex + 1} · Posición ${result.slotIndex + 1} · Nv. ${mon.level}${mon.isShiny ? ' · Variocolor' : ''}',
                              ),
                              trailing: const Icon(Icons.chevron_right),
                            ),
                          );
                        },
                      )
              : showGrid
              ? buildGrid(pokemon)
              : pokemon.isEmpty
              ? const Center(child: Text('Esta caja está vacía.'))
              : ListView.builder(
                  key: ValueKey(selectedBox),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  itemCount: pokemon.length,
                  itemBuilder: (context, index) {
                    final mon = pokemon[index];
                    return Card(
                      child: ListTile(
                        onTap: () => openPokemon(selectedBox, index),
                        trailing: const Icon(Icons.chevron_right),
                        leading: mon.isEgg
                            ? const SizedBox(
                                width: 56,
                                child: Icon(Icons.egg_outlined),
                              )
                            : PokemonSprite(speciesId: mon.speciesId),
                        title: Text(
                          mon.isEgg
                              ? 'Huevo'
                              : '${PokemonSpecies.getName(mon.speciesId)} — ${mon.nickname}',
                        ),
                        subtitle: Text(
                          mon.isEgg
                              ? 'Pendiente de eclosionar'
                              : 'Nivel ${mon.level} · Amistad: ${mon.friendship}/255\n${mon.stats!.summary}',
                        ),
                        isThreeLine: !mon.isEgg,
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _PcSearchResult {
  final int boxIndex;
  final int slotIndex;
  final CrystalBoxPokemon pokemon;

  const _PcSearchResult(this.boxIndex, this.slotIndex, this.pokemon);
}
