from pathlib import Path
from urllib.request import urlopen
sources={
'offsets.cs':'https://raw.githubusercontent.com/kwsch/PKHeX/master/PKHeX.Core/Saves/Substructures/Gen12/SAV2Offsets.cs',
'personal_c':'https://raw.githubusercontent.com/kwsch/PKHeX/master/PKHeX.Core/Resources/byte/personal/personal_c',
'moves.asm':'https://raw.githubusercontent.com/pret/pokecrystal/master/data/moves/moves.asm',
'move_names.asm':'https://raw.githubusercontent.com/pret/pokecrystal/master/data/moves/names.asm',
'item_names.asm':'https://raw.githubusercontent.com/pret/pokecrystal/master/data/items/names.asm',
'item_constants.asm':'https://raw.githubusercontent.com/pret/pokecrystal/master/constants/item_constants.asm',
'wr.asm':'https://raw.githubusercontent.com/pret/pokecrystal/master/ram/wram.asm',
}
for name,url in sources.items():
 Path('work/crystal_sources',name).write_bytes(urlopen(url,timeout=30).read())
 print(name)
