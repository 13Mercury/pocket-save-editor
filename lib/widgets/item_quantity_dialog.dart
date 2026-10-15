import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../games/crystal/crystal_inventory_reader.dart';
import 'item_sprite.dart';

class ItemQuantityDialog extends StatefulWidget {
  final CrystalInventoryItem item;
  const ItemQuantityDialog({super.key, required this.item});
  @override
  State<ItemQuantityDialog> createState() => _ItemQuantityDialogState();
}

class _ItemQuantityDialogState extends State<ItemQuantityDialog> {
  final formKey = GlobalKey<FormState>();
  late final controller = TextEditingController(
    text: '${widget.item.quantity}',
  );

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void save() {
    if (formKey.currentState!.validate()) {
      Navigator.of(context).pop(int.parse(controller.text));
    }
  }

  void changeQuantity(int amount) {
    final current = int.tryParse(controller.text) ?? widget.item.quantity;
    final updated = (current + amount).clamp(1, 99);
    setState(() => controller.text = '$updated');
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.item.name),
    content: SingleChildScrollView(
      child: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ItemSprite(itemId: widget.item.id),
            const SizedBox(height: 12),
            Row(
              children: [
                IconButton(
                  key: const Key('quantity-minus'),
                  tooltip: 'Disminuir cantidad',
                  onPressed: (int.tryParse(controller.text) ?? 1) <= 1
                      ? null
                      : () => changeQuantity(-1),
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                Expanded(
                  child: TextFormField(
                    controller: controller,
                    autofocus: true,
                    onTapOutside: (_) =>
                        FocusManager.instance.primaryFocus?.unfocus(),
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Cantidad',
                      helperText: 'De 1 a 99',
                    ),
                    validator: (value) {
                      final quantity = int.tryParse(value ?? '');
                      return quantity == null || quantity < 1 || quantity > 99
                          ? 'Introduce una cantidad de 1 a 99.'
                          : null;
                    },
                    onChanged: (_) => setState(() {}),
                    onFieldSubmitted: (_) => save(),
                  ),
                ),
                IconButton(
                  key: const Key('quantity-plus'),
                  tooltip: 'Aumentar cantidad',
                  onPressed: (int.tryParse(controller.text) ?? 99) >= 99
                      ? null
                      : () => changeQuantity(1),
                  icon: const Icon(Icons.add_circle_outline),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text('Después de guardar el cambio, exporta la partida.'),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Cancelar'),
      ),
      FilledButton(onPressed: save, child: const Text('Guardar cantidad')),
    ],
  );
}
