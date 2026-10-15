from pathlib import Path
from urllib.request import urlopen
urls={
 'item_game_indices.csv':'https://raw.githubusercontent.com/PokeAPI/pokeapi/master/data/v2/csv/item_game_indices.csv',
 'items.csv':'https://raw.githubusercontent.com/PokeAPI/pokeapi/master/data/v2/csv/items.csv',
 'item_attributes.asm':'https://raw.githubusercontent.com/pret/pokecrystal/master/data/items/attributes.asm',
}
for name,url in urls.items():
 Path('work/crystal_sources',name).write_bytes(urlopen(url,timeout=30).read())
 print(name)
