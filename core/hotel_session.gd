class_name HotelSession
extends RefCounted
## Una partita: la fila degli ospiti, i turni e le monete.
##
## COSA FA: applica il ciclo di gioco deciso con D-026. Ospitare o rifiutare l'ospite di turno
## conclude il turno: chi è in camera paga secondo come sta in quel momento, poi resta un turno in
## meno, e chi ha finito parte. Spostare le pareti è gratis e non consuma turni.
## CHI LA USA: la scena RoomEditor, che le passa le azioni del giocatore.
## PERCHÉ È SEPARATA: non usa nodi né disegno, quindi i test automatici possono provare un'intera
## partita. Non decide chi entra dove: lo chiede a Grid.
## NOTA GDSCRIPT: «extends RefCounted» crea un oggetto che non compare nella scena.

## Quanti ospiti in fila si vedono oltre a quello di turno.
const VISIBLE_UPCOMING_GUESTS: int = 2

## Le monete guadagnate finora.
var coins: int = 0
## I turni conclusi finora.
var turns_played: int = 0

## La griglia con camere e regole.
var _grid: Grid
## La fila degli ospiti in arrivo.
var _queue: GuestQueue


## Crea una partita sulla griglia indicata. _init() è la funzione che Godot chiama con .new().
func _init(grid: Grid, queue: GuestQueue) -> void:
	_grid = grid
	_queue = queue


## Restituisce l'ospite di turno.
func get_current_guest() -> Guest:
	return _queue.peek(1)[0]


## Restituisce gli ospiti visibili in fila dietro quello di turno.
func get_upcoming_guests() -> Array[Guest]:
	return _queue.peek(VISIBLE_UPCOMING_GUESTS + 1).slice(1)


## Prova a far entrare l'ospite di turno in una camera. Se riesce conclude il turno e ne restituisce
## il resoconto; se non può entrare restituisce null, e il turno continua.
func host_current_guest(room: Room) -> TurnReport:
	if not _grid.assign_guest(get_current_guest(), room):
		return null

	return _end_turn()


## Rifiuta l'ospite di turno: se ne va senza pagare e il turno si conclude (D-026).
func refuse_current_guest() -> TurnReport:
	return _end_turn()


## Conclude il turno: incassa, fa passare il tempo, fa partire chi ha finito e fa avanzare la fila.
func _end_turn() -> TurnReport:
	var report: TurnReport = TurnReport.new()

	for room: Room in _grid.get_rooms():
		if room.guest == null:
			continue

		# Il compenso dipende da come sta ora: allargare una camera conviene anche dopo (D-026).
		var fit: Need.Fit = room.guest.need.evaluate(room.cells.size)
		var amount: int = room.guest.get_pay(fit)
		report.earnings[room] = amount
		coins += amount

		room.turns_left -= 1
		if room.turns_left <= 0:
			_grid.remove_guest(room)
			report.departed_rooms.append(room)

	turns_played += 1
	_queue.advance()
	return report
