import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_save_editor/games/crystal/crystal_reader.dart';
import 'package:pocket_save_editor/games/crystal/crystal_pokemon_moves.dart';
import 'package:pocket_save_editor/games/crystal/crystal_dv_properties.dart';
import 'package:pocket_save_editor/screens/party_pokemon_detail_screen.dart';
import 'package:pocket_save_editor/screens/pokemon_edit_screen.dart';

import 'support/crystal_test_save.dart';

void main() {
  for (final cancel in [false, true]) {
    testWidgets(
      cancel
          ? 'Cancel preserves party details and save bytes'
          : 'Party editor previews and saves moves in the same page',
      (tester) async {
        tester.view.physicalSize = const Size(1000, 5000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final original = syntheticCrystalSave();
        var reader = CrystalReader(Uint8List.fromList(original));
        var selectedLevel = reader.partyLevel(5);
        final effort = reader.partyStatExperience(5);

        Future<CrystalReader?> save(PokemonEditResult result) async {
          final level = reader.withPartyLevel(5, result.level);
          final nickname = CrystalReader(level)
              .withPartyNickname(5, result.nickname);
          final friendship = CrystalReader(nickname)
              .withPartyFriendship(5, result.friendship);
          final pokerus = CrystalReader(friendship)
              .withPartyPokerusStatus(5, result.pokerusStatus);
          final training = CrystalReader(pokerus).withPartyTraining(
            5,
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
          reader = CrystalReader(
            CrystalReader(training).withPartyMoves(5, result.moves),
          );
          reader = CrystalReader(
            reader.withPartyHeldItem(5, result.heldItemId),
          );
          return reader;
        }

        await tester.pumpWidget(
          MaterialApp(
            home: PartyPokemonDetailScreen(
              reader: reader,
              index: 5,
              onSave: save,
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Equipo · Posición 6'), findsOneWidget);
        expect(find.text('Golbat'), findsOneWidget);
        expect(find.text('Pokédex #042'), findsOneWidget);
        expect(find.text('Apodo: C'), findsOneWidget);
        await tester.ensureVisible(find.text('Editar Pokémon'));
        await tester.tap(find.text('Editar Pokémon'));
        await tester.pumpAndSettle();
        expect(find.byType(PokemonEditScreen), findsOneWidget);
        await tester.enterText(
          find.byKey(const Key('pokemon-nickname')),
          'GPT-6',
        );
        final nicknameFocus = FocusManager.instance.primaryFocus;

        if (cancel) {
          await tester.ensureVisible(find.text('Cancelar'));
          await tester.tap(find.text('Cancelar'));
        } else {
          final levelSlider = find.byKey(const Key('pokemon-level-slider'));
          await tester.ensureVisible(levelSlider);
          await tester.tap(levelSlider);
          await tester.pumpAndSettle();
          expect(
            FocusManager.instance.primaryFocus,
            isNot(same(nicknameFocus)),
            reason:
                'Tapping another control should unfocus the nickname field.',
          );
          await tester.drag(levelSlider, const Offset(240, 0));
          await tester.pumpAndSettle();
          selectedLevel = tester.widget<Slider>(levelSlider).value.round();
          expect(selectedLevel, greaterThan(reader.partyLevel(5)));
          final shinySwitch = find.byKey(const Key('pokemon-shiny-switch'));
          await tester.ensureVisible(shinySwitch);
          await tester.tap(shinySwitch);
          await tester.pumpAndSettle();
          expect(tester.widget<SwitchListTile>(shinySwitch).value, isTrue);
          final genderSelector = find.byKey(
            const Key('pokemon-gender-selector'),
          );
          await tester.ensureVisible(genderSelector);
          await tester.tap(
            find.descendant(of: genderSelector, matching: find.text('Hembra')),
          );
          await tester.pumpAndSettle();
          expect(
            tester.widget<SegmentedButton<String>>(genderSelector).selected,
            {'Hembra'},
          );
          final pokerusSwitch = find.byKey(const Key('pokemon-pokerus-switch'));
          await tester.ensureVisible(pokerusSwitch);
          await tester.tap(pokerusSwitch);
          await tester.pumpAndSettle();
          expect(tester.widget<SwitchListTile>(pokerusSwitch).value, isTrue);
          final heldItem = find.byKey(const Key('pokemon-held-item'));
          await tester.ensureVisible(heldItem);
          await tester.tap(heldItem);
          await tester.pumpAndSettle();
          await tester.enterText(
            find.byKey(const Key('held-item-search')),
            'Leftovers',
          );
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const Key('held-item-146')));
          await tester.pumpAndSettle();
          await tester.ensureVisible(find.byKey(const Key('move-select-0')));
          await tester.tap(find.byKey(const Key('move-select-0')));
          await tester.pumpAndSettle();
          await tester.enterText(
            find.byKey(const Key('move-picker-search')),
            'Surf',
          );
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const Key('move-picker-item-57')));
          await tester.pumpAndSettle();
          expect(
            find.byKey(const Key('move-legality-warning')),
            findsOneWidget,
          );
          expect(
            reader.partyNicknames[5],
            'C',
            reason: 'Editing is only a preview until save.',
          );
          await tester.tap(find.byKey(const Key('move-ppups-0')));
          await tester.pumpAndSettle();
          await tester.tap(find.text('3').last);
          await tester.pumpAndSettle();
          await tester.ensureVisible(find.byKey(const Key('move-pp-plus-0')));
          await tester.tap(find.byKey(const Key('move-pp-plus-0')));
          await tester.pumpAndSettle();
          await tester.ensureVisible(find.text('Guardar cambios'));
          await tester.tap(find.text('Guardar cambios'));
        }
        await tester.pumpAndSettle();
        if (cancel) {
          expect(find.byType(PokemonEditScreen), findsNothing);
          expect(reader.data, orderedEquals(original));
          expect(find.text('Apodo: C'), findsOneWidget);
        } else {
          expect(
            find.byType(PokemonEditScreen),
            findsNothing,
            reason: 'Save returns to the detail on the same route.',
          );
          expect(find.text('Apodo: GPT-6'), findsOneWidget);
          expect(reader.partyLevel(5), selectedLevel);
          expect(find.text('Sexo'), findsOneWidget);
          expect(find.text('Hembra'), findsOneWidget);
          expect(find.text('Pokérus'), findsOneWidget);
          expect(find.text('Leftovers'), findsOneWidget);
          expect(find.text('Activo · 4 día(s)'), findsOneWidget);
          expect(find.text('$selectedLevel'), findsWidgets);
          expect(reader.partyNicknames[5], 'GPT-6');
          expect(reader.partyFriendship(5), 70);
          expect(reader.partyStatExperience(5), effort);
          final savedDvs = reader.partyDvs(5);
          expect(
            crystalGenderForDvs(42, savedDvs['attack']!, savedDvs['speed']!),
            'Hembra',
          );
          expect(
            crystalIsShinyFromDvs(
              savedDvs['attack']!,
              savedDvs['defense']!,
              savedDvs['speed']!,
              savedDvs['special']!,
            ),
            isTrue,
          );
          expect(reader.partyPokerusStatus(5), 0x14);
          expect(reader.partyHeldItemId(5), 146);
          final savedMoves = readCrystalMoves(reader.data, 0x286d + 5 * 48);
          expect(savedMoves[0].id, 57);
          expect(savedMoves[0].ppUps, 3);
          expect(savedMoves[0].currentPp, greaterThan(15));
        }
        expect(tester.takeException(), isNull);
      },
    );
  }
}
