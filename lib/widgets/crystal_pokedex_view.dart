import 'package:flutter/material.dart';

import '../core/pokemon_species.dart';
import '../games/crystal/crystal_reader.dart';
import 'pokemon_sprite.dart';

enum _DexFilter { all, seen, caught, unseen }

class CrystalPokedexView extends StatefulWidget {
  final CrystalReader reader;

  const CrystalPokedexView({super.key, required this.reader});

  @override
  State<CrystalPokedexView> createState() => _CrystalPokedexViewState();
}

class _CrystalPokedexViewState extends State<CrystalPokedexView> {
  _DexFilter _filter = _DexFilter.all;
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<int> get _species => List.generate(251, (index) => index + 1)
      .where(
        (id) =>
            (switch (_filter) {
              _DexFilter.all => true,
              _DexFilter.seen => widget.reader.hasSeenSpecies(id),
              _DexFilter.caught => widget.reader.hasCaughtSpecies(id),
              _DexFilter.unseen => !widget.reader.hasSeenSpecies(id),
            }) &&
            _matchesSearch(id),
      )
      .toList(growable: false);

  bool _matchesSearch(int speciesId) {
    if (_query.isEmpty) return true;
    final number = speciesId.toString().padLeft(3, '0');
    if (number.contains(_query)) return true;
    if (!widget.reader.hasSeenSpecies(speciesId)) return false;
    return PokemonSpecies.getName(speciesId).toLowerCase().contains(_query);
  }

  @override
  Widget build(BuildContext context) {
    final reader = widget.reader;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pokédex de Johto',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  '${reader.caughtSpeciesCount} capturados · ${reader.seenSpeciesCount} vistos de 251',
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(value: reader.caughtSpeciesCount / 251),
              ],
            ),
          ),
        ),
        TextField(
          controller: _searchController,
          onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
          decoration: InputDecoration(
            hintText: 'Buscar por nombre o número',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _query.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Limpiar búsqueda',
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _query = '');
                    },
                    icon: const Icon(Icons.close),
                  ),
            border: const OutlineInputBorder(),
            isDense: true,
          ),
          onChanged: (value) =>
              setState(() => _query = value.trim().toLowerCase()),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SegmentedButton<_DexFilter>(
            segments: const [
              ButtonSegment(value: _DexFilter.all, label: Text('Todos')),
              ButtonSegment(value: _DexFilter.seen, label: Text('Vistos')),
              ButtonSegment(
                value: _DexFilter.caught,
                label: Text('Capturados'),
              ),
              ButtonSegment(value: _DexFilter.unseen, label: Text('No vistos')),
            ],
            selected: {_filter},
            showSelectedIcon: false,
            onSelectionChanged: (selection) =>
                setState(() => _filter = selection.first),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _species.isEmpty
              ? const Center(child: Text('No hay Pokémon que coincidan.'))
              : GridView.builder(
                  itemCount: _species.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 2.5,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemBuilder: (context, index) {
                    final id = _species[index];
                    final seen = reader.hasSeenSpecies(id);
                    final caught = reader.hasCaughtSpecies(id);
                    return Card(
                      margin: EdgeInsets.zero,
                      child: Row(
                        children: [
                          const SizedBox(width: 4),
                          seen
                              ? PokemonSprite(speciesId: id)
                              : SizedBox(
                                  width: 56,
                                  height: 56,
                                  child: Icon(
                                    Icons.catching_pokemon,
                                    size: 36,
                                    color: Theme.of(context).disabledColor,
                                  ),
                                ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '#${id.toString().padLeft(3, '0')}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall,
                                  ),
                                  Text(
                                    seen
                                        ? PokemonSpecies.getName(id)
                                        : 'No visto',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Icon(
                              caught
                                  ? Icons.catching_pokemon
                                  : seen
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              size: 18,
                              color: caught
                                  ? Colors.redAccent
                                  : seen
                                  ? Colors.blueGrey
                                  : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
