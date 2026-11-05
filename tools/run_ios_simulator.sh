#!/bin/bash
# Compila il gioco e lo avvia nel simulatore iPhone già acceso, come app nativa.
#
# COSA FA: esporta il progetto Xcode con Godot, sostituisce la libreria per simulatore, compila
# e installa l'app. Non firma nulla e non tocca i file del progetto.
# CHI LO USA: chiunque voglia provare una modifica senza il telefono: ./tools/run_ios_simulator.sh
# PERCHÉ ESISTE: la libreria per simulatore dei modelli ufficiali di Godot 4.7.2 è solo per
# processori Intel, mentre questo Mac e i suoi simulatori usano arm64. La libreria giusta è stata
# compilata dai sorgenti di 4.7.2-stable con questo comando (docs/DECISIONI.md, D-023):
#   scons platform=ios target=template_debug arch=arm64 simulator=yes debug_symbols=no -j7

# Si ferma al primo comando che fallisce, invece di proseguire con un risultato incompleto.
set -euo pipefail

# Percorso dell'editor Godot: si può cambiare impostando GODOT prima di lanciare lo script.
GODOT="${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}"
# Cartella in cui si trovano le librerie compilate dai sorgenti.
LIBRARIES="$HOME/Library/Application Support/Godot/custom_templates/4.7.2-ios-simulator-arm64"
# Identificativo dell'app, uguale a quello del preset iOS (D-014).
BUNDLE_ID="com.benahq.foldingrooms.dev"
# Radice del progetto: la cartella sopra quella di questo script.
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
# Cartella temporanea fuori dal progetto: dentro, Godot importerebbe anche le immagini generate.
BUILD_DIR="${TMPDIR:-/tmp}/folding_rooms_simulator"

# Riparte da zero: i file esportati sono sempre rigenerabili.
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR/project"

# Esporta il progetto Xcode: contiene il gioco e il motore già pronti da compilare.
"$GODOT" --headless --path "$PROJECT_DIR" --export-debug iOS "$BUILD_DIR/project/FoldingRooms.xcodeproj"

# Mette la libreria arm64 al posto di quella Intel nella parte riservata al simulatore.
cp "$LIBRARIES/libgodot.ios.template_debug.arm64.simulator.a" \
	"$BUILD_DIR/project/FoldingRooms.xcframework/ios-arm64_x86_64-simulator/libgodot.a"

# Compila per il simulatore. Il simulatore non richiede il certificato di uno sviluppatore.
xcodebuild -project "$BUILD_DIR/project/FoldingRooms.xcodeproj" -scheme FoldingRooms \
	-configuration Debug -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' \
	-derivedDataPath "$BUILD_DIR/derived" ARCHS=arm64 ONLY_ACTIVE_ARCH=NO \
	CODE_SIGNING_ALLOWED=NO -quiet build

# Installa e avvia l'app sul simulatore acceso. «booted» indica quello già in funzione.
APP_PATH="$BUILD_DIR/derived/Build/Products/Debug-iphonesimulator/FoldingRooms.app"
xcrun simctl install booted "$APP_PATH"
xcrun simctl launch --terminate-running-process booted "$BUNDLE_ID"
