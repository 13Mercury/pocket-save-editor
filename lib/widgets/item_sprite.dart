import 'package:flutter/material.dart';

import '../games/crystal/crystal_item_icons.dart';
import '../games/crystal/crystal_catalog.dart';

class ItemSprite extends StatelessWidget {
  final int itemId;
  const ItemSprite({super.key, required this.itemId});

  @override
  Widget build(BuildContext context) {
    final url = crystalItemIconUrl(itemId);
    const fallback = Icon(Icons.inventory_2_outlined, size: 28);
    return SizedBox(
      width: 40,
      height: 40,
      child: url == null
          ? fallback
          : Image.network(
              url,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.none,
              semanticLabel: crystalItemName(itemId),
              errorBuilder: (context, error, stackTrace) => fallback,
              loadingBuilder: (context, child, progress) =>
                  progress == null ? child : fallback,
            ),
    );
  }
}
