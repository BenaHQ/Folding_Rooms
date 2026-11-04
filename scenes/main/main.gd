extends Control
## Scena di avvio del gioco: è la prima cosa che Godot apre.
##
## COSA FA: contiene lo sfondo, la scena del gesto RoomEditor, la barra degli ospiti GuestBar e
## le informazioni Hud, e li collega tra loro. I comportamenti stanno in quelle scene.
## CHI LA USA: Godot, che la apre da solo perché project.godot la indica come scena principale
## (run/main_scene).
## PERCHÉ È SEPARATA: quelle scene non si conoscono tra loro. Salgono con un segnale fin qui, e
## questa scena chiama direttamente il nodo interessato (AGENTS.md, sezione 6).
## NOTA GDSCRIPT: una «scena» è un albero di «nodi». «extends Control» aggiunge comportamento a
## un nodo d'interfaccia. @onready assegna la variabile appena i nodi sono pronti e $Nome trova
## il nodo figlio con quel nome. Un segnale è un avviso: connect() indica chi deve riceverlo.

## La scena delle camere.
@onready var _room_editor: RoomEditor = $RoomEditor
## La barra con l'ospite di turno e la fila.
@onready var _guest_bar: GuestBar = $GuestBar
## Le informazioni in alto: monete e turni.
@onready var _hud: Hud = $Hud


## Godot chiama _ready() quando il nodo e i suoi figli sono pronti: qui si fanno i collegamenti.
func _ready() -> void:
	_guest_bar.refuse_pressed.connect(_room_editor.refuse_current_guest)
	_room_editor.session_changed.connect(_refresh_interface)
	_refresh_interface()


## Mostra nell'interfaccia lo stato attuale della partita.
func _refresh_interface() -> void:
	var session: HotelSession = _room_editor.session
	_guest_bar.update_queue(session.get_current_guest(), session.get_upcoming_guests())
	_hud.update_values(session.coins, session.turns_played)
