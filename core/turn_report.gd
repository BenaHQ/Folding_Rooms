class_name TurnReport
extends RefCounted
## Il resoconto di un turno, cioè di una giornata: chi ha pagato quanto e chi se n'è andato.
##
## COSA FA: conserva il risultato di una giornata conclusa. Se la giornata continua perché devono
## arrivare altri ospiti, il resoconto è vuoto. È solo un contenitore di dati, senza regole.
## CHI LA USA: HotelSession lo crea; RoomEditor lo legge per mostrare i guadagni.
## PERCHÉ È SEPARATA: chi anima il risultato non deve ricalcolarlo, così non può sbagliarlo.
## NOTA GDSCRIPT: «extends RefCounted» crea un oggetto che non compare nella scena. Un Dictionary
## associa a ogni chiave un valore: qui a ogni camera il suo guadagno.

## Le monete guadagnate in questo turno da ogni camera occupata.
var earnings: Dictionary[Room, int] = {}
## Le camere il cui ospite è partito alla fine di questo turno.
var departed_rooms: Array[Room] = []


## Restituisce il totale delle monete guadagnate nel turno.
func get_total_earnings() -> int:
	var total: int = 0
	for amount: int in earnings.values():
		total += amount
	return total
