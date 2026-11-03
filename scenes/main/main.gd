extends Control
## Scena di avvio del gioco: è la prima cosa che Godot apre.
##
## COSA FA: per ora contiene soltanto lo sfondo color crema e la scena del gesto,
## RoomEditor. Tutto il comportamento sta in quella scena.
## CHI LA USA: Godot, che la apre da solo perché project.godot la indica come
## scena principale (run/main_scene).
## PERCHÉ È SEPARATA: ogni scena tiene il proprio script accanto a sé. Nelle
## prossime fasi qui si aggiungeranno le altre parti del gioco, come l'interfaccia.
## NOTA GDSCRIPT: una «scena» è un albero di «nodi», cioè i mattoni con cui Godot
## costruisce tutto ciò che compare a schermo. «extends Control» significa che
## questo script aggiunge comportamento a un nodo Control, il tipo di nodo pensato
## per riempire lo schermo e per l'interfaccia. Lo script è ancora vuoto perché
## la scena non ha comportamenti: non aggiungiamo codice che non serve.
