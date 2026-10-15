import 'crystal_gender_ratios.dart';

/// Gen II determines gender from the Attack and Speed DVs and species ratio.
String? crystalGenderForDvs(int speciesId, int attackDv, int speedDv) {
  final ratio = crystalGenderRatios[speciesId] ?? -1;
  if (ratio < 0) return null;
  if (ratio == 0) return 'Macho';
  if (ratio == 99) return 'Hembra';
  final combinedDvs = attackDv * 16 + speedDv;
  return ratio < combinedDvs ? 'Macho' : 'Hembra';
}

/// Gen II shininess is determined by this fixed DV pattern.
bool crystalIsShinyFromDvs(int attack, int defense, int speed, int special) =>
    defense == 10 &&
    speed == 10 &&
    special == 10 &&
    const {2, 3, 6, 7, 10, 11, 14, 15}.contains(attack);

/// Finds the closest Attack DV that produces [gender] at the given Speed DV.
/// When [keepShiny] is true, only Attack DVs compatible with Gen II shininess
/// are considered. Returns null when the requested combination is impossible.
int? crystalAttackDvForGender({
  required int speciesId,
  required String gender,
  required int speedDv,
  required int currentAttackDv,
  bool keepShiny = false,
}) {
  final candidates =
      [
        for (var attackDv = 0; attackDv <= 15; attackDv++)
          if ((!keepShiny ||
                  const {2, 3, 6, 7, 10, 11, 14, 15}.contains(attackDv)) &&
              crystalGenderForDvs(speciesId, attackDv, speedDv) == gender)
            attackDv,
      ]..sort((left, right) {
        final distance = (left - currentAttackDv).abs().compareTo(
          (right - currentAttackDv).abs(),
        );
        return distance != 0 ? distance : left.compareTo(right);
      });
  return candidates.isEmpty ? null : candidates.first;
}
