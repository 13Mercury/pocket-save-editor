// Power and accuracy data from the Pokémon Crystal move table.
// Source: https://github.com/pret/pokecrystal/blob/master/data/moves/moves.asm
class CrystalMoveBattleInfo {
  final int power;
  final int accuracy;
  const CrystalMoveBattleInfo(this.power, this.accuracy);
}

const crystalMoveBattleInfo = <int, CrystalMoveBattleInfo>{
  1: CrystalMoveBattleInfo(40, 100), // POUND
  2: CrystalMoveBattleInfo(50, 100), // KARATE_CHOP
  3: CrystalMoveBattleInfo(15, 85), // DOUBLESLAP
  4: CrystalMoveBattleInfo(18, 85), // COMET_PUNCH
  5: CrystalMoveBattleInfo(80, 85), // MEGA_PUNCH
  6: CrystalMoveBattleInfo(40, 100), // PAY_DAY
  7: CrystalMoveBattleInfo(75, 100), // FIRE_PUNCH
  8: CrystalMoveBattleInfo(75, 100), // ICE_PUNCH
  9: CrystalMoveBattleInfo(75, 100), // THUNDERPUNCH
  10: CrystalMoveBattleInfo(40, 100), // SCRATCH
  11: CrystalMoveBattleInfo(55, 100), // VICEGRIP
  12: CrystalMoveBattleInfo(0, 30), // GUILLOTINE
  13: CrystalMoveBattleInfo(80, 75), // RAZOR_WIND
  14: CrystalMoveBattleInfo(0, 100), // SWORDS_DANCE
  15: CrystalMoveBattleInfo(50, 95), // CUT
  16: CrystalMoveBattleInfo(40, 100), // GUST
  17: CrystalMoveBattleInfo(60, 100), // WING_ATTACK
  18: CrystalMoveBattleInfo(0, 100), // WHIRLWIND
  19: CrystalMoveBattleInfo(70, 95), // FLY
  20: CrystalMoveBattleInfo(15, 75), // BIND
  21: CrystalMoveBattleInfo(80, 75), // SLAM
  22: CrystalMoveBattleInfo(35, 100), // VINE_WHIP
  23: CrystalMoveBattleInfo(65, 100), // STOMP
  24: CrystalMoveBattleInfo(30, 100), // DOUBLE_KICK
  25: CrystalMoveBattleInfo(120, 75), // MEGA_KICK
  26: CrystalMoveBattleInfo(70, 95), // JUMP_KICK
  27: CrystalMoveBattleInfo(60, 85), // ROLLING_KICK
  28: CrystalMoveBattleInfo(0, 100), // SAND_ATTACK
  29: CrystalMoveBattleInfo(70, 100), // HEADBUTT
  30: CrystalMoveBattleInfo(65, 100), // HORN_ATTACK
  31: CrystalMoveBattleInfo(15, 85), // FURY_ATTACK
  32: CrystalMoveBattleInfo(1, 30), // HORN_DRILL
  33: CrystalMoveBattleInfo(35, 95), // TACKLE
  34: CrystalMoveBattleInfo(85, 100), // BODY_SLAM
  35: CrystalMoveBattleInfo(15, 85), // WRAP
  36: CrystalMoveBattleInfo(90, 85), // TAKE_DOWN
  37: CrystalMoveBattleInfo(90, 100), // THRASH
  38: CrystalMoveBattleInfo(120, 100), // DOUBLE_EDGE
  39: CrystalMoveBattleInfo(0, 100), // TAIL_WHIP
  40: CrystalMoveBattleInfo(15, 100), // POISON_STING
  41: CrystalMoveBattleInfo(25, 100), // TWINEEDLE
  42: CrystalMoveBattleInfo(14, 85), // PIN_MISSILE
  43: CrystalMoveBattleInfo(0, 100), // LEER
  44: CrystalMoveBattleInfo(60, 100), // BITE
  45: CrystalMoveBattleInfo(0, 100), // GROWL
  46: CrystalMoveBattleInfo(0, 100), // ROAR
  47: CrystalMoveBattleInfo(0, 55), // SING
  48: CrystalMoveBattleInfo(0, 55), // SUPERSONIC
  49: CrystalMoveBattleInfo(20, 90), // SONICBOOM
  50: CrystalMoveBattleInfo(0, 55), // DISABLE
  51: CrystalMoveBattleInfo(40, 100), // ACID
  52: CrystalMoveBattleInfo(40, 100), // EMBER
  53: CrystalMoveBattleInfo(95, 100), // FLAMETHROWER
  54: CrystalMoveBattleInfo(0, 100), // MIST
  55: CrystalMoveBattleInfo(40, 100), // WATER_GUN
  56: CrystalMoveBattleInfo(120, 80), // HYDRO_PUMP
  57: CrystalMoveBattleInfo(95, 100), // SURF
  58: CrystalMoveBattleInfo(95, 100), // ICE_BEAM
  59: CrystalMoveBattleInfo(120, 70), // BLIZZARD
  60: CrystalMoveBattleInfo(65, 100), // PSYBEAM
  61: CrystalMoveBattleInfo(65, 100), // BUBBLEBEAM
  62: CrystalMoveBattleInfo(65, 100), // AURORA_BEAM
  63: CrystalMoveBattleInfo(150, 90), // HYPER_BEAM
  64: CrystalMoveBattleInfo(35, 100), // PECK
  65: CrystalMoveBattleInfo(80, 100), // DRILL_PECK
  66: CrystalMoveBattleInfo(80, 80), // SUBMISSION
  67: CrystalMoveBattleInfo(50, 90), // LOW_KICK
  68: CrystalMoveBattleInfo(1, 100), // COUNTER
  69: CrystalMoveBattleInfo(1, 100), // SEISMIC_TOSS
  70: CrystalMoveBattleInfo(80, 100), // STRENGTH
  71: CrystalMoveBattleInfo(20, 100), // ABSORB
  72: CrystalMoveBattleInfo(40, 100), // MEGA_DRAIN
  73: CrystalMoveBattleInfo(0, 90), // LEECH_SEED
  74: CrystalMoveBattleInfo(0, 100), // GROWTH
  75: CrystalMoveBattleInfo(55, 95), // RAZOR_LEAF
  76: CrystalMoveBattleInfo(120, 100), // SOLARBEAM
  77: CrystalMoveBattleInfo(0, 75), // POISONPOWDER
  78: CrystalMoveBattleInfo(0, 75), // STUN_SPORE
  79: CrystalMoveBattleInfo(0, 75), // SLEEP_POWDER
  80: CrystalMoveBattleInfo(70, 100), // PETAL_DANCE
  81: CrystalMoveBattleInfo(0, 95), // STRING_SHOT
  82: CrystalMoveBattleInfo(40, 100), // DRAGON_RAGE
  83: CrystalMoveBattleInfo(15, 70), // FIRE_SPIN
  84: CrystalMoveBattleInfo(40, 100), // THUNDERSHOCK
  85: CrystalMoveBattleInfo(95, 100), // THUNDERBOLT
  86: CrystalMoveBattleInfo(0, 100), // THUNDER_WAVE
  87: CrystalMoveBattleInfo(120, 70), // THUNDER
  88: CrystalMoveBattleInfo(50, 90), // ROCK_THROW
  89: CrystalMoveBattleInfo(100, 100), // EARTHQUAKE
  90: CrystalMoveBattleInfo(1, 30), // FISSURE
  91: CrystalMoveBattleInfo(60, 100), // DIG
  92: CrystalMoveBattleInfo(0, 85), // TOXIC
  93: CrystalMoveBattleInfo(50, 100), // CONFUSION
  94: CrystalMoveBattleInfo(90, 100), // PSYCHIC_M
  95: CrystalMoveBattleInfo(0, 60), // HYPNOSIS
  96: CrystalMoveBattleInfo(0, 100), // MEDITATE
  97: CrystalMoveBattleInfo(0, 100), // AGILITY
  98: CrystalMoveBattleInfo(40, 100), // QUICK_ATTACK
  99: CrystalMoveBattleInfo(20, 100), // RAGE
  100: CrystalMoveBattleInfo(0, 100), // TELEPORT
  101: CrystalMoveBattleInfo(1, 100), // NIGHT_SHADE
  102: CrystalMoveBattleInfo(0, 100), // MIMIC
  103: CrystalMoveBattleInfo(0, 85), // SCREECH
  104: CrystalMoveBattleInfo(0, 100), // DOUBLE_TEAM
  105: CrystalMoveBattleInfo(0, 100), // RECOVER
  106: CrystalMoveBattleInfo(0, 100), // HARDEN
  107: CrystalMoveBattleInfo(0, 100), // MINIMIZE
  108: CrystalMoveBattleInfo(0, 100), // SMOKESCREEN
  109: CrystalMoveBattleInfo(0, 100), // CONFUSE_RAY
  110: CrystalMoveBattleInfo(0, 100), // WITHDRAW
  111: CrystalMoveBattleInfo(0, 100), // DEFENSE_CURL
  112: CrystalMoveBattleInfo(0, 100), // BARRIER
  113: CrystalMoveBattleInfo(0, 100), // LIGHT_SCREEN
  114: CrystalMoveBattleInfo(0, 100), // HAZE
  115: CrystalMoveBattleInfo(0, 100), // REFLECT
  116: CrystalMoveBattleInfo(0, 100), // FOCUS_ENERGY
  117: CrystalMoveBattleInfo(0, 100), // BIDE
  118: CrystalMoveBattleInfo(0, 100), // METRONOME
  119: CrystalMoveBattleInfo(0, 100), // MIRROR_MOVE
  120: CrystalMoveBattleInfo(200, 100), // SELFDESTRUCT
  121: CrystalMoveBattleInfo(100, 75), // EGG_BOMB
  122: CrystalMoveBattleInfo(20, 100), // LICK
  123: CrystalMoveBattleInfo(20, 70), // SMOG
  124: CrystalMoveBattleInfo(65, 100), // SLUDGE
  125: CrystalMoveBattleInfo(65, 85), // BONE_CLUB
  126: CrystalMoveBattleInfo(120, 85), // FIRE_BLAST
  127: CrystalMoveBattleInfo(80, 100), // WATERFALL
  128: CrystalMoveBattleInfo(35, 75), // CLAMP
  129: CrystalMoveBattleInfo(60, 100), // SWIFT
  130: CrystalMoveBattleInfo(100, 100), // SKULL_BASH
  131: CrystalMoveBattleInfo(20, 100), // SPIKE_CANNON
  132: CrystalMoveBattleInfo(10, 100), // CONSTRICT
  133: CrystalMoveBattleInfo(0, 100), // AMNESIA
  134: CrystalMoveBattleInfo(0, 80), // KINESIS
  135: CrystalMoveBattleInfo(0, 100), // SOFTBOILED
  136: CrystalMoveBattleInfo(85, 90), // HI_JUMP_KICK
  137: CrystalMoveBattleInfo(0, 75), // GLARE
  138: CrystalMoveBattleInfo(100, 100), // DREAM_EATER
  139: CrystalMoveBattleInfo(0, 55), // POISON_GAS
  140: CrystalMoveBattleInfo(15, 85), // BARRAGE
  141: CrystalMoveBattleInfo(20, 100), // LEECH_LIFE
  142: CrystalMoveBattleInfo(0, 75), // LOVELY_KISS
  143: CrystalMoveBattleInfo(140, 90), // SKY_ATTACK
  144: CrystalMoveBattleInfo(0, 100), // TRANSFORM
  145: CrystalMoveBattleInfo(20, 100), // BUBBLE
  146: CrystalMoveBattleInfo(70, 100), // DIZZY_PUNCH
  147: CrystalMoveBattleInfo(0, 100), // SPORE
  148: CrystalMoveBattleInfo(0, 70), // FLASH
  149: CrystalMoveBattleInfo(1, 80), // PSYWAVE
  150: CrystalMoveBattleInfo(0, 100), // SPLASH
  151: CrystalMoveBattleInfo(0, 100), // ACID_ARMOR
  152: CrystalMoveBattleInfo(90, 85), // CRABHAMMER
  153: CrystalMoveBattleInfo(250, 100), // EXPLOSION
  154: CrystalMoveBattleInfo(18, 80), // FURY_SWIPES
  155: CrystalMoveBattleInfo(50, 90), // BONEMERANG
  156: CrystalMoveBattleInfo(0, 100), // REST
  157: CrystalMoveBattleInfo(75, 90), // ROCK_SLIDE
  158: CrystalMoveBattleInfo(80, 90), // HYPER_FANG
  159: CrystalMoveBattleInfo(0, 100), // SHARPEN
  160: CrystalMoveBattleInfo(0, 100), // CONVERSION
  161: CrystalMoveBattleInfo(80, 100), // TRI_ATTACK
  162: CrystalMoveBattleInfo(1, 90), // SUPER_FANG
  163: CrystalMoveBattleInfo(70, 100), // SLASH
  164: CrystalMoveBattleInfo(0, 100), // SUBSTITUTE
  165: CrystalMoveBattleInfo(50, 100), // STRUGGLE
  166: CrystalMoveBattleInfo(0, 100), // SKETCH
  167: CrystalMoveBattleInfo(10, 90), // TRIPLE_KICK
  168: CrystalMoveBattleInfo(40, 100), // THIEF
  169: CrystalMoveBattleInfo(0, 100), // SPIDER_WEB
  170: CrystalMoveBattleInfo(0, 100), // MIND_READER
  171: CrystalMoveBattleInfo(0, 100), // NIGHTMARE
  172: CrystalMoveBattleInfo(60, 100), // FLAME_WHEEL
  173: CrystalMoveBattleInfo(40, 100), // SNORE
  174: CrystalMoveBattleInfo(0, 100), // CURSE
  175: CrystalMoveBattleInfo(1, 100), // FLAIL
  176: CrystalMoveBattleInfo(0, 100), // CONVERSION2
  177: CrystalMoveBattleInfo(100, 95), // AEROBLAST
  178: CrystalMoveBattleInfo(0, 85), // COTTON_SPORE
  179: CrystalMoveBattleInfo(1, 100), // REVERSAL
  180: CrystalMoveBattleInfo(0, 100), // SPITE
  181: CrystalMoveBattleInfo(40, 100), // POWDER_SNOW
  182: CrystalMoveBattleInfo(0, 100), // PROTECT
  183: CrystalMoveBattleInfo(40, 100), // MACH_PUNCH
  184: CrystalMoveBattleInfo(0, 90), // SCARY_FACE
  185: CrystalMoveBattleInfo(60, 100), // FAINT_ATTACK
  186: CrystalMoveBattleInfo(0, 75), // SWEET_KISS
  187: CrystalMoveBattleInfo(0, 100), // BELLY_DRUM
  188: CrystalMoveBattleInfo(90, 100), // SLUDGE_BOMB
  189: CrystalMoveBattleInfo(20, 100), // MUD_SLAP
  190: CrystalMoveBattleInfo(65, 85), // OCTAZOOKA
  191: CrystalMoveBattleInfo(0, 100), // SPIKES
  192: CrystalMoveBattleInfo(100, 50), // ZAP_CANNON
  193: CrystalMoveBattleInfo(0, 100), // FORESIGHT
  194: CrystalMoveBattleInfo(0, 100), // DESTINY_BOND
  195: CrystalMoveBattleInfo(0, 100), // PERISH_SONG
  196: CrystalMoveBattleInfo(55, 95), // ICY_WIND
  197: CrystalMoveBattleInfo(0, 100), // DETECT
  198: CrystalMoveBattleInfo(25, 80), // BONE_RUSH
  199: CrystalMoveBattleInfo(0, 100), // LOCK_ON
  200: CrystalMoveBattleInfo(90, 100), // OUTRAGE
  201: CrystalMoveBattleInfo(0, 100), // SANDSTORM
  202: CrystalMoveBattleInfo(60, 100), // GIGA_DRAIN
  203: CrystalMoveBattleInfo(0, 100), // ENDURE
  204: CrystalMoveBattleInfo(0, 100), // CHARM
  205: CrystalMoveBattleInfo(30, 90), // ROLLOUT
  206: CrystalMoveBattleInfo(40, 100), // FALSE_SWIPE
  207: CrystalMoveBattleInfo(0, 90), // SWAGGER
  208: CrystalMoveBattleInfo(0, 100), // MILK_DRINK
  209: CrystalMoveBattleInfo(65, 100), // SPARK
  210: CrystalMoveBattleInfo(10, 95), // FURY_CUTTER
  211: CrystalMoveBattleInfo(70, 90), // STEEL_WING
  212: CrystalMoveBattleInfo(0, 100), // MEAN_LOOK
  213: CrystalMoveBattleInfo(0, 100), // ATTRACT
  214: CrystalMoveBattleInfo(0, 100), // SLEEP_TALK
  215: CrystalMoveBattleInfo(0, 100), // HEAL_BELL
  216: CrystalMoveBattleInfo(1, 100), // RETURN
  217: CrystalMoveBattleInfo(1, 90), // PRESENT
  218: CrystalMoveBattleInfo(1, 100), // FRUSTRATION
  219: CrystalMoveBattleInfo(0, 100), // SAFEGUARD
  220: CrystalMoveBattleInfo(0, 100), // PAIN_SPLIT
  221: CrystalMoveBattleInfo(100, 95), // SACRED_FIRE
  222: CrystalMoveBattleInfo(1, 100), // MAGNITUDE
  223: CrystalMoveBattleInfo(100, 50), // DYNAMICPUNCH
  224: CrystalMoveBattleInfo(120, 85), // MEGAHORN
  225: CrystalMoveBattleInfo(60, 100), // DRAGONBREATH
  226: CrystalMoveBattleInfo(0, 100), // BATON_PASS
  227: CrystalMoveBattleInfo(0, 100), // ENCORE
  228: CrystalMoveBattleInfo(40, 100), // PURSUIT
  229: CrystalMoveBattleInfo(20, 100), // RAPID_SPIN
  230: CrystalMoveBattleInfo(0, 100), // SWEET_SCENT
  231: CrystalMoveBattleInfo(100, 75), // IRON_TAIL
  232: CrystalMoveBattleInfo(50, 95), // METAL_CLAW
  233: CrystalMoveBattleInfo(70, 100), // VITAL_THROW
  234: CrystalMoveBattleInfo(0, 100), // MORNING_SUN
  235: CrystalMoveBattleInfo(0, 100), // SYNTHESIS
  236: CrystalMoveBattleInfo(0, 100), // MOONLIGHT
  237: CrystalMoveBattleInfo(1, 100), // HIDDEN_POWER
  238: CrystalMoveBattleInfo(100, 80), // CROSS_CHOP
  239: CrystalMoveBattleInfo(40, 100), // TWISTER
  240: CrystalMoveBattleInfo(0, 90), // RAIN_DANCE
  241: CrystalMoveBattleInfo(0, 90), // SUNNY_DAY
  242: CrystalMoveBattleInfo(80, 100), // CRUNCH
  243: CrystalMoveBattleInfo(1, 100), // MIRROR_COAT
  244: CrystalMoveBattleInfo(0, 100), // PSYCH_UP
  245: CrystalMoveBattleInfo(80, 100), // EXTREMESPEED
  246: CrystalMoveBattleInfo(60, 100), // ANCIENTPOWER
  247: CrystalMoveBattleInfo(80, 100), // SHADOW_BALL
  248: CrystalMoveBattleInfo(80, 90), // FUTURE_SIGHT
  249: CrystalMoveBattleInfo(20, 100), // ROCK_SMASH
  250: CrystalMoveBattleInfo(15, 70), // WHIRLPOOL
  251: CrystalMoveBattleInfo(10, 100), // BEAT_UP
};

const _crystalPhysicalTypes = <int>{0, 1, 2, 3, 4, 5, 7, 8, 9};

String crystalMoveDamageCategory(int moveId, int typeId) {
  final info = crystalMoveBattleInfo[moveId];
  if (info == null) return 'Desconocido';
  if (info.power == 0 && !const {12, 32, 90}.contains(moveId)) {
    return 'Estado';
  }
  return _crystalPhysicalTypes.contains(typeId) ? 'Físico' : 'Especial';
}

int crystalTypeColorValue(int typeId) => switch (typeId) {
  0 => 0xff8a8a72,
  1 => 0xffc03028,
  2 => 0xffa890f0,
  3 => 0xffa040a0,
  4 => 0xffe0c068,
  5 => 0xffb8a038,
  7 => 0xffa8b820,
  8 => 0xff705898,
  9 => 0xffb8b8d0,
  19 => 0xff68a090,
  20 => 0xfff08030,
  21 => 0xff6890f0,
  22 => 0xff78c850,
  23 => 0xfff8d030,
  24 => 0xfff85888,
  25 => 0xff98d8d8,
  26 => 0xff7038f8,
  27 => 0xff705848,
  _ => 0xff808080,
};
