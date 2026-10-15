import 'dart:typed_data';

import '../widgets/crystal_pc_view.dart';
import '../widgets/crystal_inventory_view.dart';
import '../widgets/crystal_pokedex_view.dart';
import '../widgets/crystal_trainer_profile_view.dart';
import '../widgets/crystal_trainer_edit_dialog.dart';
import '../core/pokemon_species.dart';
import '../widgets/pokemon_sprite.dart';
import 'pokemon_edit_screen.dart';
import 'party_pokemon_detail_screen.dart';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:file_saver/file_saver.dart';

import '../games/crystal/crystal_checksum.dart';
import '../games/crystal/crystal_reader.dart';
import '../games/crystal/crystal_pc_reader.dart';
import '../games/crystal/crystal_dv_properties.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  CrystalReader? crystal;
  Uint8List? lastExportedData;
  String? fileName;
  String? errorMessage;
  final List<Uint8List> _undoSnapshots = [];
  final List<String> _pendingChangeDescriptions = [];
  int _selectedSection = 0;

  void _recordPendingChange(
    CrystalReader before,
    Uint8List after,
    String label,
  ) {
    if (_bytesEqual(before.data, after)) return;
    if (lastExportedData != null && _bytesEqual(after, lastExportedData!)) {
      _undoSnapshots.clear();
      _pendingChangeDescriptions.clear();
      return;
    }
    _undoSnapshots.add(Uint8List.fromList(before.data));
    _pendingChangeDescriptions.add(label);
  }

  bool _bytesEqual(Uint8List a, Uint8List b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  void undoLastChange() {
    final snapshot = _undoSnapshots.isEmpty
        ? null
        : _undoSnapshots.removeLast();
    final current = crystal;
    if (snapshot == null || current == null) return;
    setState(() {
      crystal = CrystalReader(Uint8List.fromList(snapshot));
      if (_pendingChangeDescriptions.isNotEmpty) {
        _pendingChangeDescriptions.removeLast();
      }
      errorMessage = null;
    });
  }

  void _showPendingChanges() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cambios pendientes'),
        content: _pendingChangeDescriptions.isEmpty
            ? const Text('La partida coincide con el archivo importado.')
            : SizedBox(
                width: 360,
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (
                      var index = 0;
                      index < _pendingChangeDescriptions.length;
                      index++
                    )
                      ListTile(
                        leading: CircleAvatar(child: Text('${index + 1}')),
                        title: Text(_pendingChangeDescriptions[index]),
                      ),
                    const Text(
                      'El archivo original no cambia hasta que exportes la partida.',
                    ),
                  ],
                ),
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _applyInventoryChange(Uint8List data) {
    final current = crystal;
    if (current == null) return;
    _recordPendingChange(current, data, 'Objetos de la mochila');
    setState(() {
      crystal = CrystalReader(data);
      errorMessage = null;
    });
  }

  Future<void> _editTrainerProfile() async {
    final current = crystal;
    if (current == null) return;
    final changes = await showDialog<CrystalTrainerProfileChanges>(
      context: context,
      builder: (context) => CrystalTrainerEditDialog(reader: current),
    );
    if (changes == null || !mounted) return;
    try {
      final updated = current.withTrainerProfile(
        trainerName: changes.trainerName,
        rivalName: changes.rivalName,
        money: changes.money,
        coins: changes.coins,
        johtoBadges: changes.johtoBadges,
        kantoBadges: changes.kantoBadges,
      );
      _recordPendingChange(current, updated, 'Perfil del entrenador');
      setState(() {
        crystal = CrystalReader(updated);
        errorMessage = null;
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo actualizar el perfil: $error')),
      );
    }
  }

  bool get hasPendingChanges {
    final currentData = crystal?.data;
    final savedData = lastExportedData;

    if (currentData == null || savedData == null) return false;
    if (currentData.length != savedData.length) return true;

    for (var i = 0; i < currentData.length; i++) {
      if (currentData[i] != savedData[i]) return true;
    }
    return false;
  }

  Future<void> exportSave() async {
    final current = crystal;

    if (current == null) return;

    try {
      final editorSnapshot = Uint8List.fromList(current.data);
      // Crear una copia independiente de la partida.
      final modifiedData = Uint8List.fromList(editorSnapshot);

      // Sincronizar respaldo y actualizar checksums.
      CrystalChecksum.synchronizeBackup(modifiedData);

      // Verificar la integridad antes de exportar.
      if (!CrystalChecksum.isPrimaryValid(modifiedData) ||
          !CrystalChecksum.isBackupValid(modifiedData)) {
        throw Exception('Error al validar los checksums.');
      }

      // Guardar como archivo .sav.
      final savedPath = await FileSaver.instance.saveAs(
        name: 'pocket_save_edited',
        bytes: modifiedData,
        fileExtension: 'sav',
        mimeType: MimeType.custom,
        customMimeType: 'application/octet-stream',
      );

      // On iOS, the document picker returns null if the user cancels.
      if (savedPath == null) return;
      if (!mounted) return;

      setState(() {
        // Guardamos el estado del editor previo a actualizar checksums. Así,
        // las diferencias técnicas de exportación no se consideran ediciones.
        lastExportedData = editorSnapshot;
        _pendingChangeDescriptions.clear();
        _undoSnapshots.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Partida guardada como pocket_save_edited.sav'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error al exportar: $e')));
    }
  }

  Future<void> importSave() async {
    try {
      final files = await FilePicker.pickFiles(type: FileType.any);

      if (files.isEmpty) return;

      final file = files.first;

      if (!file.name.toLowerCase().endsWith('.sav')) {
        throw Exception('Selecciona un archivo .sav');
      }

      final Uint8List bytes = await file.readAsBytes();

      if (bytes.length != 32768) {
        throw Exception('El archivo debe tener 32768 bytes.');
      }

      final reader = CrystalReader(bytes);

      if (!mounted) return;

      setState(() {
        crystal = reader;
        lastExportedData = Uint8List.fromList(bytes);
        fileName = file.name;
        errorMessage = null;
        _pendingChangeDescriptions.clear();
        _undoSnapshots.clear();
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        errorMessage = e.toString();
      });
    }
  }

  Future<CrystalReader?> editPokemon(
    int index,
    PokemonEditResult result,
  ) async {
    final current = crystal;

    if (current == null) return null;

    try {
      // Ajusta nivel, experiencia, stats y PS antes de aplicar los otros cambios.
      final levelData = current.withPartyLevel(index, result.level);

      // Después modificamos el apodo.
      final nicknameData = CrystalReader(levelData)
          .withPartyNickname(index, result.nickname);

      // Después modificamos la amistad.
      final updatedData = CrystalReader(nicknameData)
          .withPartyFriendship(index, result.friendship);
      final updatedWithPokerus = CrystalReader(updatedData)
          .withPartyPokerusStatus(index, result.pokerusStatus);
      final updatedWithTraining = CrystalReader(updatedWithPokerus)
          .withPartyTraining(
            index,
            attackDv: result.attackDv,
            defenseDv: result.defenseDv,
            speedDv: result.speedDv,
            specialDv: result.specialDv,
            hp: result.hpStatExp,
            attack: result.attackStatExp,
            defense: result.defenseStatExp,
            speed: result.speedStatExp,
            special: result.specialStatExp,
          );
      final withMoves = CrystalReader(updatedWithTraining)
          .withPartyMoves(index, result.moves);
      final withHeldItem = CrystalReader(withMoves)
          .withPartyHeldItem(index, result.heldItemId);
      final updatedReader = CrystalReader(withHeldItem);
      final nickname = current.partyNicknames[index];
      _recordPendingChange(
        current,
        updatedReader.data,
        'Edición de ${PokemonSpecies.getName(current.partySpecies[index])} · $nickname',
      );

      // Actualiza el equipo sin salir de la ficha donde se está editando.
      setState(() {
        crystal = updatedReader;
        errorMessage = null;
      });
      return updatedReader;
    } catch (e) {
      if (mounted) setState(() => errorMessage = e.toString());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudieron guardar los cambios: $e')),
        );
      }
      return null;
    }
  }

  Future<CrystalReader?> editBoxPokemon(
    int boxIndex,
    int slotIndex,
    PokemonEditResult result,
  ) async {
    final current = crystal;
    if (current == null) return null;

    try {
      final boxPokemon = CrystalPcReader(current.data).readBox(boxIndex);
      if (slotIndex < 0 || slotIndex >= boxPokemon.length) return null;
      final speciesId = boxPokemon[slotIndex].speciesId;

      final levelData = current.withBoxLevel(boxIndex, slotIndex, result.level);
      final nicknameData = CrystalReader(levelData)
          .withBoxNickname(boxIndex, slotIndex, result.nickname);
      final friendshipData = CrystalReader(nicknameData)
          .withBoxFriendship(boxIndex, slotIndex, result.friendship);
      final pokerusData = CrystalReader(friendshipData)
          .withBoxPokerusStatus(boxIndex, slotIndex, result.pokerusStatus);
      final trainingData = CrystalReader(pokerusData).withBoxTraining(
        boxIndex,
        slotIndex,
        attackDv: result.attackDv,
        defenseDv: result.defenseDv,
        speedDv: result.speedDv,
        specialDv: result.specialDv,
        hp: result.hpStatExp,
        attack: result.attackStatExp,
        defense: result.defenseStatExp,
        speed: result.speedStatExp,
        special: result.specialStatExp,
      );
      final movesData = CrystalReader(trainingData)
          .withBoxMoves(boxIndex, slotIndex, result.moves);
      final heldItemData = CrystalReader(movesData)
          .withBoxHeldItem(boxIndex, slotIndex, result.heldItemId);
      final updatedReader = CrystalReader(heldItemData);
      _recordPendingChange(
        current,
        updatedReader.data,
        'Edición de ${PokemonSpecies.getName(speciesId)} · Caja ${boxIndex + 1}',
      );
      setState(() {
        crystal = updatedReader;
        errorMessage = null;
      });
      return updatedReader;
    } catch (e) {
      if (mounted) setState(() => errorMessage = e.toString());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudieron guardar los cambios: $e')),
        );
      }
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pocket Save Editor'),
        centerTitle: true,
        actions: [
          if (crystal != null) ...[
            IconButton(
              tooltip: 'Importar otra partida',
              onPressed: importSave,
              icon: const Icon(Icons.folder_open),
            ),
            IconButton(
              tooltip: 'Exportar partida',
              onPressed: exportSave,
              icon: const Icon(Icons.download),
            ),
          ],
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(crystal == null ? 20 : 16),
        child: crystal == null
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(),
                  const Icon(
                    Icons.catching_pokemon,
                    size: 72,
                    color: Colors.redAccent,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Pokémon Save Editor',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: importSave,
                    icon: const Icon(Icons.folder_open),
                    label: const Text('Import Save File'),
                  ),
                  if (errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  const Spacer(),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              fileName ?? 'Partida cargada',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Pokémon en equipo: ${crystal!.partyCount}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: hasPendingChanges
                          ? Colors.amber.withValues(alpha: 0.16)
                          : Colors.green.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          hasPendingChanges
                              ? Icons.pending_outlined
                              : Icons.check_circle_outline,
                          size: 18,
                          color: hasPendingChanges
                              ? Colors.orange.shade800
                              : Colors.green.shade800,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            hasPendingChanges
                                ? 'Cambios pendientes de exportar'
                                : 'Sin cambios pendientes',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: hasPendingChanges
                                  ? Colors.orange.shade900
                                  : Colors.green.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (hasPendingChanges)
                    Wrap(
                      alignment: WrapAlignment.end,
                      spacing: 4,
                      children: [
                        TextButton.icon(
                          onPressed: _showPendingChanges,
                          icon: const Icon(Icons.list_alt),
                          label: Text(
                            'Ver cambios (${_pendingChangeDescriptions.length})',
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _undoSnapshots.isEmpty
                              ? null
                              : undoLastChange,
                          icon: const Icon(Icons.undo),
                          label: Text(
                            _undoSnapshots.length > 1
                                ? 'Deshacer (${_undoSnapshots.length})'
                                : 'Deshacer último',
                          ),
                        ),
                      ],
                    ),
                  if (errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        errorMessage!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  const Divider(height: 16),
                  Expanded(
                    child: IndexedStack(
                      index: _selectedSection,
                      children: [
                        _buildTeamGrid(context),
                        CrystalPcView(
                          data: crystal!.data,
                          onSave: editBoxPokemon,
                        ),
                        CrystalInventoryView(
                          data: crystal!.data,
                          onChanged: _applyInventoryChange,
                        ),
                        CrystalPokedexView(reader: crystal!),
                        CrystalTrainerProfileView(
                          reader: crystal!,
                          onEdit: _editTrainerProfile,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
      bottomNavigationBar: crystal == null
          ? null
          : NavigationBar(
              selectedIndex: _selectedSection,
              onDestinationSelected: (index) =>
                  setState(() => _selectedSection = index),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.groups_outlined),
                  selectedIcon: Icon(Icons.groups),
                  label: 'Equipo',
                ),
                NavigationDestination(
                  icon: Icon(Icons.storage_outlined),
                  selectedIcon: Icon(Icons.storage),
                  label: 'PC',
                ),
                NavigationDestination(
                  icon: Icon(Icons.backpack_outlined),
                  selectedIcon: Icon(Icons.backpack),
                  label: 'Objetos',
                ),
                NavigationDestination(
                  icon: Icon(Icons.menu_book_outlined),
                  selectedIcon: Icon(Icons.menu_book),
                  label: 'Pokédex',
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_outline),
                  selectedIcon: Icon(Icons.person),
                  label: 'Perfil',
                ),
              ],
            ),
    );
  }

  Widget _buildTeamGrid(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final columns = constraints.maxWidth >= 700 ? 3 : 2;
      final rows = (crystal!.partyCount / columns).ceil().clamp(1, 6);
      final tileWidth = (constraints.maxWidth - (columns - 1) * 8) / columns;
      final tileHeight = (constraints.maxHeight - (rows - 1) * 8) / rows;
      final aspectRatio = (tileWidth / tileHeight).clamp(1.05, 1.9);

      return GridView.builder(
        padding: const EdgeInsets.only(bottom: 4),
        itemCount: crystal!.partyCount,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          childAspectRatio: aspectRatio,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemBuilder: (context, index) {
          final reader = crystal!;
          final speciesId = reader.partySpecies[index];
          final nickname = reader.partyNicknames[index];
          final dvs = reader.partyDvs(index);
          final isShiny = crystalIsShinyFromDvs(
            dvs['attack']!,
            dvs['defense']!,
            dvs['speed']!,
            dvs['special']!,
          );
          return Card(
            margin: EdgeInsets.zero,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => Navigator.of(context).push<void>(
                MaterialPageRoute(
                  builder: (context) => PartyPokemonDetailScreen(
                    reader: reader,
                    index: index,
                    onSave: (result) => editPokemon(index, result),
                  ),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    PokemonSprite(
                      speciesId: speciesId,
                      isShiny: isShiny,
                      size: 76,
                    ),
                    Text(
                      PokemonSpecies.getName(speciesId),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      nickname,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Nv. ${reader.partyLevel(index)}',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                        if (isShiny) ...[
                          const SizedBox(width: 5),
                          const Icon(Icons.auto_awesome, size: 13),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}
