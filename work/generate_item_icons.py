import csv,json,re
from pathlib import Path
p=Path('work/crystal_sources')
files={r['name'] for r in json.loads((p/'item_sprite_files.json').read_text())}
items={r['id']:r['identifier'] for r in csv.DictReader((p/'items.csv').open())}
m={int(r['game_index']):items[r['item_id']] for r in csv.DictReader((p/'item_game_indices.csv').open()) if r['generation_id']=='2'}
# Resolve conflicting upstream index entries using pokecrystal's item constants.
m[0x74]='blue-card'
moveTypes={line.strip()[5:].split(',')[0].strip():line.split(',')[3].strip().replace('_TYPE','').lower() for line in (p/'moves.asm').read_text().splitlines() if line.strip().startswith('move ')}
machines=re.findall(r'^\s*add_(tm|hm)\s+(\w+)\s*;\s*([0-9a-f]+)',(p/'item_constants.asm').read_text(),re.M)
for kind,move,num in machines:
 typ=moveTypes[move]
 if typ=='curse':typ='normal' # ??? type in Crystal; use the neutral disc icon.
 m[int(num,16)]=f'{kind}-{typ}'
attrs=[line for line in (p/'item_attributes.asm').read_text().splitlines() if line.strip().startswith('item_attribute ')]
keys=[i for i,line in enumerate(attrs,1) if re.search(r',\s*KEY_ITEM\s*,',line)]
assert 7 in keys and 0x74 in keys
icons={i:n for i,n in m.items() if n+'.png' in files and i<255}
s='''// Icon filenames verified in https://github.com/PokeAPI/sprites/tree/master/sprites/items
// Gen II item IDs from PokeAPI item_game_indices.csv, corrected against
// pret/pokecrystal constants/item_constants.asm; key items from data/items/attributes.asm.
const crystalItemIconNames = <int, String>{
'''
s+=''.join(f"  {i}: '{name}',\n" for i,name in sorted(icons.items()))
s+='};\n\nconst crystalKeyItems = <int>{'+', '.join(map(str,keys))+'};\n'
s+='''
String? crystalItemIconUrl(int id) {
  final name = crystalItemIconNames[id];
  return name == null ? null :
    'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/items/$name.png';
}
'''
Path('lib/games/crystal/crystal_item_icons.dart').write_text(s)
print('Verified icons:',len(icons),'Key items:',len(keys))
