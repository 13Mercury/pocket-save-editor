import 'package:flutter/material.dart';

import '../core/pokemon_species.dart';
import '../games/crystal/crystal_catalog.dart';
import '../games/crystal/crystal_pc_reader.dart';
import '../widgets/pokemon_sprite.dart';
import '../widgets/item_sprite.dart';
import '../games/crystal/crystal_held_items.dart';

class PokemonDetailScreen extends StatelessWidget {
  final CrystalBoxPokemon pokemon;
  final String location;
  final VoidCallback? onEdit;

  const PokemonDetailScreen({
    super.key,
    required this.pokemon,
    required this.location,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final mon = pokemon;
    final stats = mon.stats;
    final theme = Theme.of(context);
    Widget field(String label, String value) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          const SizedBox(width: 16),
          Text(value, style: theme.textTheme.titleMedium),
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Ficha del Pokémon')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(location, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                SizedBox(
                  height: 112,
                  child: Center(
                    child: mon.isEgg
                        ? const Icon(Icons.egg_outlined, size: 88)
                        : Transform.scale(
                            scale: 2,
                            child: PokemonSprite(
                              speciesId: mon.speciesId,
                              isShiny: mon.isShiny,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  mon.isEgg ? 'Huevo' : PokemonSpecies.getName(mon.speciesId),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium,
                ),
                if (!mon.isEgg) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Pokédex #${mon.speciesId.toString().padLeft(3, '0')}',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    children: [
                      for (final type in crystalTypesFor(mon.speciesId))
                        Chip(label: Text(type)),
                    ],
                  ),
                  if (mon.isShiny)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Chip(
                        avatar: Icon(Icons.auto_awesome),
                        label: Text('Variocolor'),
                      ),
                    ),
                  const SizedBox(height: 12),
                  Text(
                    'Apodo: ${mon.nickname}',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 20),
                  Card(
                    child: Column(
                      children: [
                        field('Nivel', '${mon.level}'),
                        const Divider(height: 1),
                        if (mon.gender != null) ...[
                          field('Sexo', mon.gender!),
                          const Divider(height: 1),
                        ],
                        field('Amistad', '${mon.friendship}/255'),
                        const Divider(height: 1),
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                          ),
                          leading: mon.heldItemId == 0
                              ? const Icon(Icons.block)
                              : ItemSprite(itemId: mon.heldItemId),
                          title: Text(
                            mon.heldItemId == 0
                                ? 'Sin objeto'
                                : crystalItemName(mon.heldItemId),
                          ),
                          subtitle: Text(
                            crystalHeldItemDescription(mon.heldItemId),
                          ),
                        ),
                        const Divider(height: 1),
                        field(
                          'Pokérus',
                          _pokerusDescription(mon.pokerusStatus),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('Estadísticas', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 8),
                  if (stats != null)
                    Card(
                      child: Column(
                        children: [
                          field('PS máximos', '${stats.hp}'),
                          const Divider(height: 1),
                          field('Ataque', '${stats.attack}'),
                          const Divider(height: 1),
                          field('Defensa', '${stats.defense}'),
                          const Divider(height: 1),
                          field('Ataque Especial', '${stats.specialAttack}'),
                          const Divider(height: 1),
                          field('Defensa Especial', '${stats.specialDefense}'),
                          const Divider(height: 1),
                          field('Velocidad', '${stats.speed}'),
                        ],
                      ),
                    ),
                  const SizedBox(height: 20),
                  Text('Movimientos', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Card(
                    child: Column(
                      children: [
                        for (var slot = 0; slot < 4; slot++) ...[
                          if (slot > 0) const Divider(height: 1),
                          ListTile(
                            leading: Text('${slot + 1}'),
                            title: Text(
                              slot < mon.moves.length
                                  ? mon.moves[slot].name
                                  : 'Sin movimiento',
                            ),
                            subtitle:
                                slot < mon.moves.length &&
                                    mon.moves[slot].id != 0
                                ? Text(
                                    'PP ${mon.moves[slot].currentPp}/${mon.moves[slot].maxPp ?? '?'}',
                                  )
                                : null,
                          ),
                        ],
                      ],
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 20),
                  const Text(
                    'Pendiente de eclosionar',
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 20),
                if (onEdit != null && !mon.isEgg)
                  FilledButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit),
                    label: const Text('Editar Pokémon'),
                  )
                else
                  Text(
                    onEdit == null
                        ? 'PC · Solo lectura'
                        : 'Equipo · Solo lectura',
                    textAlign: TextAlign.center,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _pokerusDescription(int status) {
    final days = status & 0x0f;
    if (days > 0) return 'Activo · $days día(s)';
    if ((status & 0xf0) > 0) return 'Curado · inmune';
    return 'No';
  }
}
