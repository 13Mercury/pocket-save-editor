from pathlib import Path
import re
src=Path('work/crystal_sources')
names=re.findall(r'\bli "([^"]+)"', (src/'move_names.asm').read_text())
items=re.findall(r'\bli "([^"]+)"', (src/'item_names.asm').read_text())
rows=[line.split(';')[0].strip()[5:].split(',') for line in (src/'moves.asm').read_text().splitlines() if line.strip().startswith('move ')]
assert len(rows)==len(names)==251
assert len(items)==256
mapping={r[0].strip():i for i,r in enumerate(rows,1)}
types={'NORMAL':0,'FIGHTING':1,'FLYING':2,'POISON':3,'GROUND':4,'ROCK':5,'BIRD':6,'BUG':7,'STEEL':9,'GHOST':8,'CURSE_TYPE':19,'FIRE':20,'WATER':21,'GRASS':22,'ELECTRIC':23,'PSYCHIC_TYPE':24,'ICE':25,'DRAGON':26,'DARK':27}
# Game type constants use BUG=7, GHOST=8, STEEL=9. PKHeX personal_c uses the same IDs.
b=(src/'personal_c').read_bytes()
print('Magnemite types',list(b[81*32+7:81*32+9]))
def quote(s): return "'"+s.replace('\\','\\\\').replace("'","\\'").replace('$','\\$')+"'"
def display(s): return s.replace('#','POKé').title()
s='''// Offline Crystal data. Sources:
// https://github.com/pret/pokecrystal/tree/master/data/moves
// https://github.com/pret/pokecrystal/blob/master/data/items/names.asm
// https://github.com/pret/pokecrystal/blob/master/constants/item_constants.asm
// https://github.com/kwsch/PKHeX/blob/master/PKHeX.Core/Resources/byte/personal/personal_c
class CrystalMoveInfo {
  final String name;
  final int typeId;
  final int basePp;
  const CrystalMoveInfo(this.name, this.typeId, this.basePp);
}

const crystalTypeNames = <int, String>{
  0: 'Normal', 1: 'Lucha', 2: 'Volador', 3: 'Veneno', 4: 'Tierra',
  5: 'Roca', 7: 'Bicho', 8: 'Fantasma', 9: 'Acero', 19: '???',
  20: 'Fuego', 21: 'Agua', 22: 'Planta', 23: 'Eléctrico',
  24: 'Psíquico', 25: 'Hielo', 26: 'Dragón', 27: 'Siniestro',
};

const crystalSpeciesTypes = <int, List<int>>{
'''
# PersonalInfo2 uses compact type indices (skip Bird and unused 10..19)? verify table below.
for i in range(1,252):
 ts=list(dict.fromkeys(b[i*32+7:i*32+9]));s+=f'  {i}: {ts},\n'
s+='};\n\nconst crystalMoves = <int, CrystalMoveInfo>{\n'
for i,(name,row) in enumerate(zip(names,rows),1):
 typ=row[3].strip()
 assert typ in types,typ
 s+=f'  {i}: CrystalMoveInfo({quote(display(name))}, {types[typ]}, {int(row[5])}),\n'
s+='};\n\nconst crystalItemNames = <int, String>{\n'
for i,name in enumerate(items[:254],1):
 if name=='TERU-SAMA': continue
 label = name if re.match(r"[TH]M\d", name) else display(name)
 s+=f'  {i}: {quote(label)},\n'
s+='};\n\nconst crystalMachineItems = <int>[\n'
machines=[i for i,n in enumerate(items,1) if re.fullmatch(r'(TM|HM)\d\d',n)]
assert len(machines)==57
s+='  '+', '.join(map(str,machines))+'\n];\n'
const=(src/'item_constants.asm').read_text()
moveIds=[mapping[m] for m in re.findall(r'^\s*add_(?:tm|hm)\s+(\w+)\s*;',const,re.M)]
assert len(moveIds)==57
s+='\nconst crystalMachineMoves = <int>[\n  '+', '.join(map(str,moveIds))+'\n];\n'
s+='''
String crystalItemName(int id) => crystalItemNames[id] ?? 'Objeto desconocido (#$id)';

List<String> crystalTypesFor(int speciesId) => [
  for (final type in crystalSpeciesTypes[speciesId] ?? <int>[])
    crystalTypeNames[type] ?? 'Desconocido',
];
'''
Path('lib/games/crystal/crystal_catalog.dart').write_text(s)
