import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../games/crystal/crystal_inventory_reader.dart';
import 'item_sprite.dart';
import 'item_quantity_dialog.dart';

class CrystalInventoryView extends StatefulWidget {
  final Uint8List data;
  final ValueChanged<Uint8List>? onChanged;
  const CrystalInventoryView({super.key, required this.data, this.onChanged});
  @override
  State<CrystalInventoryView> createState() => _CrystalInventoryViewState();
}

class _CrystalInventoryViewState extends State<CrystalInventoryView> {
  CrystalPocket selected = CrystalPocket.items;

  Future<void> editQuantity(int index, CrystalInventoryItem item) async {
    final pocket = selected;
    final original = widget.data;
    final quantity = await showDialog<int>(
      context: context,
      builder: (_) => ItemQuantityDialog(item: item),
    );
    if (!mounted || quantity == null || quantity == item.quantity) return;
    if (!identical(original, widget.data)) return;
    try {
      final updated = CrystalInventoryReader(original)
          .withQuantity(pocket, index, quantity);
      widget.onChanged?.call(updated);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Cantidad actualizada. Exporta la partida para guardar el archivo.',
          ),
        ),
      );
    } on FormatException catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    List<CrystalInventoryItem> items = [];
    String? error;
    try {
      items = CrystalInventoryReader(widget.data).read(selected);
    } on FormatException catch (e) {
      error = e.message;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButton<CrystalPocket>(
          value: selected,
          isExpanded: true,
          items: [
            for (final pocket in CrystalPocket.values)
              DropdownMenuItem(value: pocket, child: Text(pocket.label)),
          ],
          onChanged: (value) {
            if (value != null) setState(() => selected = value);
          },
        ),
        Text(
          widget.onChanged == null
              ? 'Objetos · Solo lectura'
              : 'Toca un objeto para editar su cantidad.',
        ),
        if (widget.onChanged != null)
          const Text('Objetos clave y MO: cantidad fija.'),
        if (error == null)
          Text('${items.length}/${selected.capacity} espacios ocupados'),
        const SizedBox(height: 8),
        Expanded(
          child: error != null
              ? Center(child: Text(error, textAlign: TextAlign.center))
              : items.isEmpty
              ? const Center(child: Text('No hay objetos aquí.'))
              : ListView.builder(
                  key: ValueKey(selected),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return Card(
                      child: ListTile(
                        leading: ItemSprite(itemId: item.id),
                        onTap:
                            widget.onChanged != null &&
                                !item.hasFixedQuantity &&
                                selected != CrystalPocket.keyItems
                            ? () => editQuantity(index, item)
                            : null,
                        title: Text(item.name),
                        trailing: selected == CrystalPocket.keyItems
                            ? null
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('×${item.quantity}'),
                                  if (widget.onChanged != null &&
                                      !item.hasFixedQuantity) ...[
                                    const SizedBox(width: 8),
                                    const Icon(Icons.edit_outlined, size: 18),
                                  ],
                                ],
                              ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
