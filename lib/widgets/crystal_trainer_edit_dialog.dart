import 'package:flutter/material.dart';

import '../games/crystal/crystal_reader.dart';

class CrystalTrainerProfileChanges {
  final String trainerName;
  final String rivalName;
  final int money;
  final int coins;
  final List<bool> johtoBadges;
  final List<bool> kantoBadges;

  const CrystalTrainerProfileChanges({
    required this.trainerName,
    required this.rivalName,
    required this.money,
    required this.coins,
    required this.johtoBadges,
    required this.kantoBadges,
  });
}

class CrystalTrainerEditDialog extends StatefulWidget {
  final CrystalReader reader;

  const CrystalTrainerEditDialog({super.key, required this.reader});

  @override
  State<CrystalTrainerEditDialog> createState() =>
      _CrystalTrainerEditDialogState();
}

class _CrystalTrainerEditDialogState extends State<CrystalTrainerEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _trainerName;
  late final TextEditingController _rivalName;
  late final TextEditingController _money;
  late final TextEditingController _coins;
  late List<bool> _johtoBadges;
  late List<bool> _kantoBadges;

  @override
  void initState() {
    super.initState();
    final reader = widget.reader;
    _trainerName = TextEditingController(text: reader.trainerName);
    _rivalName = TextEditingController(text: reader.rivalName);
    _money = TextEditingController(text: reader.money.toString());
    _coins = TextEditingController(text: reader.coins.toString());
    _johtoBadges = reader.johtoBadges;
    _kantoBadges = reader.kantoBadges;
  }

  @override
  void dispose() {
    _trainerName.dispose();
    _rivalName.dispose();
    _money.dispose();
    _coins.dispose();
    super.dispose();
  }

  String? _validateName(String? value, String label) {
    final name = value?.trim() ?? '';
    if (name.isEmpty) return 'Escribe el nombre del $label.';
    if (name.length > 10) return 'Usa hasta 10 caracteres.';
    if (!RegExp(r'^[A-Za-z0-9 -]+$').hasMatch(name)) {
      return 'Usa letras, números, espacios o guiones.';
    }
    return null;
  }

  String? _validateNumber(String? value, {required int maximum}) {
    final parsed = int.tryParse(value ?? '');
    if (parsed == null) return 'Escribe un número válido.';
    if (parsed < 0 || parsed > maximum) {
      final groupedMaximum = maximum.toString().replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'),
        (_) => ',',
      );
      return 'El máximo es $groupedMaximum.';
    }
    return null;
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(
      CrystalTrainerProfileChanges(
        trainerName: _trainerName.text.trim(),
        rivalName: _rivalName.text.trim(),
        money: int.parse(_money.text),
        coins: int.parse(_coins.text),
        johtoBadges: List.unmodifiable(_johtoBadges),
        kantoBadges: List.unmodifiable(_kantoBadges),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Editar perfil'),
    scrollable: true,
    content: SizedBox(
      width: 420,
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _trainerName,
              maxLength: 10,
              onTapOutside: (_) =>
                  FocusManager.instance.primaryFocus?.unfocus(),
              decoration: const InputDecoration(labelText: 'Entrenador'),
              validator: (value) => _validateName(value, 'entrenador'),
            ),
            TextFormField(
              controller: _rivalName,
              maxLength: 10,
              onTapOutside: (_) =>
                  FocusManager.instance.primaryFocus?.unfocus(),
              decoration: const InputDecoration(labelText: 'Rival'),
              validator: (value) => _validateName(value, 'rival'),
            ),
            TextFormField(
              controller: _money,
              keyboardType: TextInputType.number,
              onTapOutside: (_) =>
                  FocusManager.instance.primaryFocus?.unfocus(),
              decoration: const InputDecoration(
                labelText: 'Dinero',
                prefixText: '\$',
                helperText: 'Máximo: 999,999',
              ),
              validator: (value) => _validateNumber(value, maximum: 999999),
            ),
            TextFormField(
              controller: _coins,
              keyboardType: TextInputType.number,
              onTapOutside: (_) =>
                  FocusManager.instance.primaryFocus?.unfocus(),
              decoration: const InputDecoration(
                labelText: 'Monedas',
                helperText: 'Máximo: 9,999',
              ),
              validator: (value) => _validateNumber(value, maximum: 9999),
            ),
            const SizedBox(height: 12),
            _badgeOptions(
              context,
              title: 'Medallas de Johto',
              names: CrystalReader.johtoBadgeNames,
              values: _johtoBadges,
              onChanged: (index, value) =>
                  setState(() => _johtoBadges[index] = value),
            ),
            const SizedBox(height: 8),
            _badgeOptions(
              context,
              title: 'Medallas de Kanto',
              names: CrystalReader.kantoBadgeNames,
              values: _kantoBadges,
              onChanged: (index, value) =>
                  setState(() => _kantoBadges[index] = value),
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Cancelar'),
      ),
      FilledButton(onPressed: _save, child: const Text('Guardar cambios')),
    ],
  );

  Widget _badgeOptions(
    BuildContext context, {
    required String title,
    required List<String> names,
    required List<bool> values,
    required void Function(int index, bool selected) onChanged,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Align(alignment: Alignment.centerLeft, child: Text(title)),
      Wrap(
        spacing: 4,
        runSpacing: 0,
        children: [
          for (var index = 0; index < names.length; index++)
            FilterChip(
              label: Text(names[index]),
              selected: values[index],
              onSelected: (selected) => onChanged(index, selected),
            ),
        ],
      ),
    ],
  );
}
