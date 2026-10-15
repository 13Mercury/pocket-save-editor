import 'package:flutter/material.dart';

import '../games/crystal/crystal_reader.dart';

class CrystalTrainerProfileView extends StatelessWidget {
  final CrystalReader reader;
  final VoidCallback onEdit;

  const CrystalTrainerProfileView({
    super.key,
    required this.reader,
    required this.onEdit,
  });

  String _formatNumber(int value) => value.toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ',',
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.only(bottom: 12),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 38,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: ClipOval(
                    child: Image.network(
                      reader.isFemale
                          ? 'https://archives.bulbagarden.net/media/upload/9/9e/Spr_C_Kris.png'
                          : 'https://archives.bulbagarden.net/media/upload/2/2d/Spr_C_Ethan.png',
                      width: 72,
                      height: 72,
                      filterQuality: FilterQuality.none,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        reader.isFemale ? Icons.face_3 : Icons.face_6,
                        size: 48,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                      loadingBuilder: (context, child, progress) =>
                          progress == null
                          ? child
                          : Icon(
                              reader.isFemale ? Icons.face_3 : Icons.face_6,
                              size: 48,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reader.trainerName.isEmpty
                            ? 'Entrenador'
                            : reader.trainerName,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('Perfil de Pokémon Cristal'),
                      if (reader.rivalName.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text('Rival: ${reader.rivalName}'),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: OutlinedButton.icon(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Editar perfil'),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.payments_outlined,
                label: 'Dinero',
                value: '\$${_formatNumber(reader.money)}',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatCard(
                icon: Icons.toll_outlined,
                label: 'Monedas',
                value: _formatNumber(reader.coins),
              ),
            ),
          ],
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Medallas', style: theme.textTheme.titleLarge),
                const SizedBox(height: 4),
                Text('${reader.badgeCount} de 16 conseguidas'),
                const SizedBox(height: 12),
                _BadgeGroup(
                  title: 'Johto',
                  names: CrystalReader.johtoBadgeNames,
                  earned: reader.johtoBadges,
                  icons: _johtoBadgeIcons,
                  colors: _johtoBadgeColors,
                ),
                const SizedBox(height: 12),
                _BadgeGroup(
                  title: 'Kanto',
                  names: CrystalReader.kantoBadgeNames,
                  earned: reader.kantoBadges,
                  icons: _kantoBadgeIcons,
                  colors: _kantoBadgeColors,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 8),
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    ),
  );
}

class _BadgeGroup extends StatelessWidget {
  final String title;
  final List<String> names;
  final List<bool> earned;
  final List<IconData> icons;
  final List<Color> colors;

  const _BadgeGroup({
    required this.title,
    required this.names,
    required this.earned,
    required this.icons,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 6),
      Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (var i = 0; i < names.length; i++)
            Chip(
              avatar: Icon(
                icons[i],
                size: 20,
                color: earned[i] ? colors[i] : Theme.of(context).disabledColor,
              ),
              label: Text(names[i]),
              visualDensity: VisualDensity.compact,
              side: BorderSide(
                color: earned[i] ? colors[i] : Theme.of(context).dividerColor,
              ),
              backgroundColor: earned[i]
                  ? colors[i].withValues(alpha: 0.12)
                  : null,
            ),
        ],
      ),
    ],
  );
}

const _johtoBadgeIcons = <IconData>[
  Icons.air,
  Icons.bug_report,
  Icons.circle_outlined,
  Icons.cloud,
  Icons.bolt,
  Icons.diamond_outlined,
  Icons.ac_unit,
  Icons.water_drop,
];

const _johtoBadgeColors = <Color>[
  Color(0xFF607D8B),
  Color(0xFFD79B00),
  Color(0xFF8D6E63),
  Color(0xFF8E70B6),
  Color(0xFF317AC1),
  Color(0xFF64748B),
  Color(0xFF45A6C7),
  Color(0xFF268B80),
];

const _kantoBadgeIcons = <IconData>[
  Icons.terrain,
  Icons.water_drop,
  Icons.electric_bolt,
  Icons.local_florist,
  Icons.favorite,
  Icons.psychology_alt,
  Icons.local_fire_department,
  Icons.public,
];

const _kantoBadgeColors = <Color>[
  Color(0xFF806C56),
  Color(0xFF3482C2),
  Color(0xFFDAAB19),
  Color(0xFF45925A),
  Color(0xFFD15D78),
  Color(0xFF7965AE),
  Color(0xFFD76F3E),
  Color(0xFF71924E),
];
