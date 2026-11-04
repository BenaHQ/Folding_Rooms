class_name Guest
extends Resource
## Un ospite dell'hotel: il suo bisogno e l'aspetto segnaposto.
##
## COSA FA: conserva i dati di un ospite, letti da un file .tres in data/guests/: il bisogno, per
## quanti turni resta e quanto paga a ogni turno, secondo come sta (D-026).
## CHI LA USA: Room ricorda quale ospite ospita; RoomEditor e GuestBar lo disegnano.
## PERCHÉ È SEPARATA: aggiungere un ospite significa aggiungere un file di dati, senza toccare
## il codice (AGENTS.md, sezione 6).
## NOTA GDSCRIPT: «extends Resource» crea un oggetto di dati salvabile in un file .tres.
## @export rende una variabile visibile nell'editor e salvabile in quel file.

## Il bisogno di forma dell'ospite.
@export var need: Need
## Per quanti turni resta, compreso quello in cui arriva.
@export var stay_turns: int = 1
## Monete pagate a ogni turno se sta bene.
@export var comfortable_pay: int = 0
## Monete pagate a ogni turno se è stipato o se la camera è troppo grande per lui.
@export var uncomfortable_pay: int = 0
## Misura del corpo disegnato, in celle: larghezza e altezza. Non è una regola: decide solo il
## disegno. Le regole usano need.
@export var body_size_cells: Vector2 = Vector2.ONE
## Colore segnaposto del corpo.
@export var body_color: Color = Color.WHITE


## Restituisce le monete pagate in un turno, dato come sta l'ospite. Non modifica nulla.
func get_pay(fit: Need.Fit) -> int:
	match fit:
		Need.Fit.COMFORTABLE:
			return comfortable_pay
		Need.Fit.DOES_NOT_FIT:
			# Una camera occupata non può diventare troppo piccola: resta solo per completezza.
			return 0
		_:
			return uncomfortable_pay
