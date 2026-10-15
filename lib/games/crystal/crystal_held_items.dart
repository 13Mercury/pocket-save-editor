import 'package:flutter/material.dart';

import '../../widgets/item_sprite.dart';
import 'crystal_catalog.dart';

// Items with a held effect in Pokémon Crystal's item_attributes.asm.
// IDs are the game's item IDs (1-based), matching crystalItemNames.
const crystalHeldItemIds = <int>{
  3,
  35,
  73,
  74,
  76,
  77,
  78,
  79,
  80,
  81,
  82,
  83,
  84,
  88,
  91,
  94,
  95,
  96,
  98,
  102,
  104,
  106,
  107,
  108,
  109,
  113,
  117,
  119,
  125,
  138,
  139,
  140,
  143,
  146,
  150,
  151,
  170,
  173,
  174,
};

const _heldItemDescriptions = <int, String>{
  3: 'Puede reducir la precisión del rival.',
  35: 'Aumenta la Defensa de Ditto.',
  73: 'A veces permite atacar primero.',
  74: 'Cura el envenenamiento al activarse.',
  76: 'Potencia los movimientos de tipo Tierra.',
  77: 'Potencia los movimientos de tipo Volador.',
  78: 'Cura la parálisis al activarse.',
  79: 'Descongela al Pokémon al activarse.',
  80: 'Cura las quemaduras al activarse.',
  81: 'Potencia los movimientos de tipo Veneno.',
  82: 'Puede hacer retroceder al rival.',
  83: 'Cura la confusión al activarse.',
  84: 'Despierta al Pokémon al activarse.',
  88: 'Potencia los movimientos de tipo Bicho.',
  91: 'Aumenta el dinero recibido en combates.',
  94: 'Reduce los encuentros con Pokémon salvajes.',
  95: 'Potencia los movimientos de tipo Agua.',
  96: 'Potencia los movimientos de tipo Psíquico.',
  98: 'Potencia los movimientos de tipo Lucha.',
  102: 'Potencia los movimientos de tipo Siniestro.',
  104: 'Potencia los movimientos de tipo Normal.',
  106: 'Permite huir de combates salvajes.',
  107: 'Potencia los movimientos de tipo Hielo.',
  108: 'Potencia los movimientos de tipo Eléctrico.',
  109: 'Cura un problema de estado al activarse.',
  113: 'Potencia los movimientos de tipo Fantasma.',
  117: 'Potencia los movimientos de tipo Planta.',
  119: 'A veces evita que el Pokémon se debilite.',
  125: 'Potencia los movimientos de tipo Roca.',
  138: 'Potencia los movimientos de tipo Fuego.',
  139: 'Restaura PS al activarse.',
  140: 'Aumenta la probabilidad de golpe crítico.',
  143: 'Potencia los movimientos de tipo Acero.',
  146: 'Restaura algunos PS al final de cada turno.',
  150: 'Restaura PP al activarse.',
  151: 'Potencia los movimientos de tipo Dragón.',
  170: 'Potencia los movimientos de tipo Normal.',
  173: 'Restaura PS al activarse.',
  174: 'Restaura PS al activarse.',
};

String crystalHeldItemDescription(int itemId) => itemId == 0
    ? 'Este Pokémon no lleva ningún objeto.'
    : _heldItemDescriptions[itemId] ??
          'Objeto equipado guardado en la partida.';

Future<int?> showCrystalHeldItemPicker(
  BuildContext context, {
  required int currentItemId,
}) => showModalBottomSheet<int>(
  context: context,
  isScrollControlled: true,
  builder: (context) => _CrystalHeldItemPicker(currentItemId: currentItemId),
);

class _CrystalHeldItemPicker extends StatefulWidget {
  final int currentItemId;

  const _CrystalHeldItemPicker({required this.currentItemId});

  @override
  State<_CrystalHeldItemPicker> createState() => _CrystalHeldItemPickerState();
}

class _CrystalHeldItemPickerState extends State<_CrystalHeldItemPicker> {
  String query = '';

  @override
  Widget build(BuildContext context) {
    final ids = <int>{0, ...crystalHeldItemIds};
    if (widget.currentItemId > 0) ids.add(widget.currentItemId);
    final items =
        ids
            .where(
              (id) =>
                  crystalItemName(id)
                      .toLowerCase()
                      .contains(query.toLowerCase()),
            )
            .toList()
          ..sort((a, b) {
            if (a == 0) return -1;
            if (b == 0) return 1;
            return crystalItemName(a).compareTo(crystalItemName(b));
          });
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.78,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(
                'Objeto equipado',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                autofocus: true,
                key: const Key('held-item-search'),
                onTapOutside: (_) =>
                    FocusManager.instance.primaryFocus?.unfocus(),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Buscar objeto',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => setState(() => query = value.trim()),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final id = items[index];
                  return ListTile(
                    key: Key('held-item-$id'),
                    leading: id == 0
                        ? const Icon(Icons.block)
                        : ItemSprite(itemId: id),
                    title: Text(id == 0 ? 'Sin objeto' : crystalItemName(id)),
                    subtitle: Text(crystalHeldItemDescription(id)),
                    selected: id == widget.currentItemId,
                    onTap: () => Navigator.of(context).pop(id),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
