import 'package:flutter/material.dart';

import '../core/pokemon_species.dart';

class PokemonSprite extends StatelessWidget {
  final int speciesId;
  final bool isShiny;
  final double size;

  const PokemonSprite({
    super.key,
    required this.speciesId,
    this.isShiny = false,
    this.size = 56,
  });

  @override
  Widget build(BuildContext context) {
    final url = isShiny
        ? PokemonSpecies.crystalShinySpriteUrl(speciesId)
        : PokemonSpecies.crystalSpriteUrl(speciesId);
    const fallback = Icon(Icons.catching_pokemon, size: 40);
    return SizedBox(
      width: size,
      height: size,
      child: url == null
          ? fallback
          : Image.network(
              url,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.none,
              semanticLabel: PokemonSpecies.getName(speciesId),
              errorBuilder: (context, error, stackTrace) => fallback,
              loadingBuilder: (context, child, progress) =>
                  progress == null ? child : fallback,
            ),
    );
  }
}
