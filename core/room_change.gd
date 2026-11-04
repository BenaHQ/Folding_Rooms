class_name RoomChange
extends RefCounted
## Una modifica prevista a una camera vicina, causata dallo spostamento di una parete.
##
## COSA FA: ricorda quale camera cambierebbe e quali celle occuperebbe. È solo un contenitore
## di dati, senza regole.
## CHI LA USA: Grid la crea e la inserisce in ResizePreview; la scena RoomEditor la legge per
## mostrare insieme le due modifiche.
## PERCHÉ È SEPARATA: abbina in modo esplicito camera e celle, così nessuno deve tenere due
## elenchi paralleli sperando che restino allineati.
## NOTA GDSCRIPT: «extends RefCounted» crea un oggetto che non compare nella scena e che Godot
## elimina da solo quando nessuno lo usa più.

## La camera vicina che cambierebbe.
var room: Room
## Le celle che occuperebbe dopo la modifica.
var resulting_cells: Rect2i


## Crea la modifica. _init() è la funzione che Godot chiama con RoomChange.new().
func _init(changed_room: Room, new_cells: Rect2i) -> void:
	room = changed_room
	resulting_cells = new_cells
