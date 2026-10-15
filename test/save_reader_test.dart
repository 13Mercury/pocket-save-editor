// This test intentionally prints byte-level diagnostics when run by hand.
// ignore_for_file: avoid_print
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_save_editor/core/save_reader.dart';
import 'package:pocket_save_editor/core/pokemon_text_decoder.dart';
import 'package:pocket_save_editor/games/crystal/crystal_reader.dart';
import 'package:pocket_save_editor/core/pokemon_species.dart';
import 'package:pocket_save_editor/games/crystal/crystal_checksum.dart';
import 'package:flutter/foundation.dart';

import 'support/crystal_test_save.dart';

void main() {
  test('Valida el tamaño de una partida', () {
    final data = Uint8List(32768);
    final reader = SaveReader(data);

    expect(reader.hasValidSize, true);
    expect(reader.fileSize, 32768);
  });

  test('Detecta un tamaño incorrecto', () {
    final data = Uint8List(32769);
    final reader = SaveReader(data);

    expect(reader.hasValidSize, false);
  });

  test('Lee correctamente un byte', () {
    final data = Uint8List(32768);

    data[100] = 255;

    final reader = SaveReader(data);

    expect(reader.readByte(100), 255);
    expect(reader.readHex(100), 'FF');
  });

  test('Lee una partida sintética de Pokémon Cristal', () async {
    final data = syntheticCrystalSave();
    final reader = SaveReader(data);

    expect(reader.hasValidSize, true);

    print('Tamaño: ${reader.fileSize} bytes');
    print('Primer byte: ${reader.readHex(0)}');
    print('Byte 100: ${reader.readHex(100)}');
  });

  test('Lee el nombre del entrenador de Pokémon Cristal', () async {
    final data = syntheticCrystalSave();

    // Nombre del entrenador en Pokémon Cristal.
    const trainerNameOffset = 0x200B;
    const trainerNameLength = 11;

    final nameBytes = data.sublist(
      trainerNameOffset,
      trainerNameOffset + trainerNameLength,
    );

    final trainerName = PokemonTextDecoder.decode(nameBytes);

    print('Nombre del entrenador: $trainerName');

    expect(trainerName.isNotEmpty, true);
  });

  test('Lee el equipo de Pokémon Cristal', () async {
    final data = syntheticCrystalSave();

    final crystal = CrystalReader(data);

    print('Cantidad de Pokémon: ${crystal.partyCount}');

    final species = crystal.partySpecies;

    for (int i = 0; i < species.length; i++) {
      final speciesId = species[i];
      final pokemonName = PokemonSpecies.getName(speciesId);

      print('Pokémon ${i + 1}: $pokemonName (#$speciesId)');
    }

    expect(crystal.partyCount, inInclusiveRange(0, 6));
    expect(species.length, crystal.partyCount);
  });

  test('Lee los apodos del equipo Pokémon', () async {
    final data = syntheticCrystalSave();

    final crystal = CrystalReader(data);

    final species = crystal.partySpecies;
    final nicknames = crystal.partyNicknames;

    for (int i = 0; i < species.length; i++) {
      final speciesName = PokemonSpecies.getName(species[i]);

      print('Pokémon ${i + 1}: $speciesName | Apodo: ${nicknames[i]}');
    }

    expect(nicknames.length, crystal.partyCount);
  });

  test('Cambia el apodo de Golbat sin modificar el original', () async {
    final originalData = syntheticCrystalSave();

    final crystal = CrystalReader(originalData);

    // El sexto Pokémon es Golbat (índice 5).
    final modifiedData = crystal.withPartyNickname(5, 'GPT-6');

    // Leer la copia modificada.
    final modifiedCrystal = CrystalReader(modifiedData);

    print('Apodo original: ${crystal.partyNicknames[5]}');
    print('Apodo modificado: ${modifiedCrystal.partyNicknames[5]}');

    // Verificar que el cambio funcionó.
    expect(modifiedCrystal.partyNicknames[5], 'GPT-6');

    // Verificar que el original sigue intacto.
    expect(crystal.partyNicknames[5], 'C');

    // El tamaño de la partida no debe cambiar.
    expect(modifiedData.length, originalData.length);

    // Comprobar que solamente cambió la región del apodo.
    const nicknameOffset = 0x29CF + (5 * 11);

    for (int i = 0; i < originalData.length; i++) {
      if (i < nicknameOffset || i >= nicknameOffset + 11) {
        expect(
          modifiedData[i],
          originalData[i],
          reason: 'Se modificó inesperadamente el byte $i',
        );
      }
    }
  });

  test('Inspecciona regiones de la partida de Cristal', () async {
    final data = syntheticCrystalSave();

    void inspect(int offset, int length) {
      final bytes = data.sublist(offset, offset + length);

      final hex = bytes
          .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
          .join(' ')
          .toUpperCase();

      print('Offset 0x${offset.toRadixString(16).toUpperCase()}: $hex');
    }

    print('\n--- DIAGNÓSTICO DE PARTIDA ---');

    print('Tamaño: ${data.length} bytes');

    inspect(0x0000, 16);
    inspect(0x2000, 16);
    inspect(0x2D00, 16);
    inspect(0x2D60, 16);
    inspect(0x2D80, 16);
    inspect(0x7E00, 16);

    expect(data.length, 32768);
  });

  test('Verifica checksums de Pokémon Cristal', () async {
    final data = syntheticCrystalSave();

    final primaryCalculated = CrystalChecksum.calculate(
      data,
      CrystalChecksum.primaryStart,
      CrystalChecksum.primaryEnd,
    );

    final primaryStored = CrystalChecksum.readStored(
      data,
      CrystalChecksum.primaryChecksumOffset,
    );

    final backupCalculated = CrystalChecksum.calculate(
      data,
      CrystalChecksum.backupStart,
      CrystalChecksum.backupEnd,
    );

    final backupStored = CrystalChecksum.readStored(
      data,
      CrystalChecksum.backupChecksumOffset,
    );

    String hex(int value) =>
        '0x${value.toRadixString(16).padLeft(4, '0').toUpperCase()}';

    print('\n--- CHECKSUMS DE POKÉMON CRISTAL ---');

    print(
      'Principal: calculado=${hex(primaryCalculated)}, '
      'guardado=${hex(primaryStored)}',
    );

    print(
      'Respaldo: calculado=${hex(backupCalculated)}, '
      'guardado=${hex(backupStored)}',
    );

    print('Principal válido: ${CrystalChecksum.isPrimaryValid(data)}');
    print('Respaldo válido: ${CrystalChecksum.isBackupValid(data)}');

    expect(data.length, 32768);
  });

  test('Actualiza checksum después de cambiar el apodo', () async {
    final originalData = syntheticCrystalSave();

    final crystal = CrystalReader(originalData);

    // Cambiar el apodo de Golbat.
    final modifiedData = crystal.withPartyNickname(5, 'GPT-6');

    // Actualizar el checksum principal.
    CrystalChecksum.update(modifiedData);

    // Comprobar que el checksum es válido.
    expect(CrystalChecksum.isPrimaryValid(modifiedData), true);

    // Comprobar que el apodo se modificó.
    final modifiedCrystal = CrystalReader(modifiedData);

    expect(modifiedCrystal.partyNicknames[5], 'GPT-6');

    // Verificar que el original sigue intacto.
    expect(CrystalReader(originalData).partyNicknames[5], 'C');

    print('Apodo modificado: ${modifiedCrystal.partyNicknames[5]}');
    print('Checksum principal actualizado correctamente.');
  });

  test('Sincroniza el respaldo después de cambiar el apodo', () async {
    final originalData = syntheticCrystalSave();

    final crystal = CrystalReader(originalData);

    final modifiedData = crystal.withPartyNickname(5, 'GPT-6');

    CrystalChecksum.synchronizeBackup(modifiedData);

    expect(CrystalChecksum.isPrimaryValid(modifiedData), true);
    expect(CrystalChecksum.isBackupValid(modifiedData), true);

    expect(CrystalReader(modifiedData).partyNicknames[5], 'GPT-6');

    expect(modifiedData.length, 32768);

    print('Checksum principal: válido');
    print('Checksum respaldo: válido');
    print('Apodo de Golbat: GPT-6');
  });

  test('Compara los apodos entre principal y respaldo', () async {
    final data = syntheticCrystalSave();

    const primaryOffset = 0x2A06;
    const backupOffset = 0x1C06;
    const length = 11;

    final primaryBytes = data.sublist(primaryOffset, primaryOffset + length);

    final backupBytes = data.sublist(backupOffset, backupOffset + length);

    print('Principal: ${PokemonTextDecoder.decode(primaryBytes)}');
    print('Respaldo: ${PokemonTextDecoder.decode(backupBytes)}');

    print('Bytes iguales: ${listEquals(primaryBytes, backupBytes)}');
  });

  test('Compara las regiones completas de la partida', () async {
    final data = syntheticCrystalSave();

    const primaryStart = 0x2009;
    const backupStart = 0x1209;
    const length = 0x2B82 - 0x2009 + 1;

    int differences = 0;

    for (int i = 0; i < length; i++) {
      if (data[primaryStart + i] != data[backupStart + i]) {
        differences++;
      }
    }

    print('Bytes comparados: $length');
    print('Bytes diferentes: $differences');

    expect(data.length, 32768);
  });

  test('Solo modifica el apodo y los checksums', () async {
    final original = syntheticCrystalSave();

    final crystal = CrystalReader(original);
    final modified = crystal.withPartyNickname(5, 'GPT-6');

    CrystalChecksum.synchronizeBackup(modified);

    const primaryNickname = 0x29CF + (5 * 11);
    const backupNickname = primaryNickname - 0xE00;

    final allowedOffsets = <int>{};

    for (int i = 0; i < 11; i++) {
      allowedOffsets.add(primaryNickname + i);
      allowedOffsets.add(backupNickname + i);
    }

    allowedOffsets.addAll({
      CrystalChecksum.primaryChecksumOffset,
      CrystalChecksum.primaryChecksumOffset + 1,
      CrystalChecksum.backupChecksumOffset,
      CrystalChecksum.backupChecksumOffset + 1,
    });

    final unexpectedChanges = <int>[];

    for (int i = 0; i < original.length; i++) {
      if (original[i] != modified[i] && !allowedOffsets.contains(i)) {
        unexpectedChanges.add(i);
      }
    }

    print('Cambios inesperados: ${unexpectedChanges.length}');

    expect(unexpectedChanges, isEmpty);
    expect(CrystalChecksum.isPrimaryValid(modified), true);
    expect(CrystalChecksum.isBackupValid(modified), true);
  });

  test('Exporta partida modificada de Pokémon Cristal', () async {
    final originalData = syntheticCrystalSave();

    // Cambiar el apodo de Golbat.
    final crystal = CrystalReader(originalData);
    final modifiedData = crystal.withPartyNickname(5, 'GPT-6');

    // Sincronizar respaldo y checksums.
    CrystalChecksum.synchronizeBackup(modifiedData);

    // Verificar antes de exportar.
    expect(CrystalChecksum.isPrimaryValid(modifiedData), true);
    expect(CrystalChecksum.isBackupValid(modifiedData), true);
    expect(CrystalReader(modifiedData).partyNicknames[5], 'GPT-6');

    // Crear una copia independiente.
    final outputFile = File(
      '${Directory.systemTemp.path}/crystal_gpt6_test.sav',
    );

    await outputFile.writeAsBytes(modifiedData);

    print('Partida exportada: ${outputFile.path}');
    print('Tamaño: ${await outputFile.length()} bytes');
    print('Apodo de Golbat: GPT-6');
  });

  test('Lee y modifica la amistad de Golbat', () async {
    final original = syntheticCrystalSave();

    final crystal = CrystalReader(original);

    // Golbat es el sexto Pokémon del equipo.
    final friendship = crystal.partyFriendship(5);

    print('Amistad original de Golbat: $friendship/255');
    print('Puede evolucionar: ${friendship >= 220}');

    // Establecer amistad máxima.
    final modified = crystal.withPartyFriendship(5, 255);

    // Sincronizar checksums y respaldo.
    CrystalChecksum.synchronizeBackup(modified);

    final editedCrystal = CrystalReader(modified);

    expect(editedCrystal.partyFriendship(5), 255);
    expect(CrystalChecksum.isPrimaryValid(modified), true);
    expect(CrystalChecksum.isBackupValid(modified), true);

    // Confirmar que el original no cambió.
    expect(CrystalReader(original).partyFriendship(5), friendship);

    // Comprobar que el nivel de Golbat sigue siendo 51.
    final levelOffset = 0x286D + (5 * 48) + 31;
    expect(modified[levelOffset], 51);

    // Exportar una copia experimental.
    final output = File(
      '${Directory.systemTemp.path}/crystal_friendship_test.sav',
    );
    await output.writeAsBytes(modified);

    print('Nueva amistad: ${editedCrystal.partyFriendship(5)}/255');
    print('Archivo generado: ${output.path}');
  });
}
