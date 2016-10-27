#!/bin/bash

# schalter: Pfad Quelle (-q); Pfad Ziel (-z); maximale Groesse der Bilder (-g); Hilfe (-h); Override (-o); Anleitung (-t); noch nicht vorhandene Dateien hinzufügen -> Add (-a)
# wenn angabe nicht da: Aktuelle Dir für Quelle und beim Zielpfad Order erstellen

#TODO: Datei mehrmals ausfuehren, wenn man ein genaueres Ergebnis haben will -> oefter mit kleineren Schritten ausfuehren liefert immer genaueres Ergebnis

getProcess () {
	if [ -z "$1" ]                           # Is parameter #1 zero length?
	then
		return 1
	fi

	picNum="${1-$DEFAULT}"

	if [ -z "$2" ]                           # Is parameter #2 zero length?
	then
		return 1
	fi

	maxPics="${2-$DEFAULT}"

	if [ -z "$3" ]                           # Is parameter #3 zero length?
	then
		return 1
	fi

	name="${3-$DEFAULT}"

	if [ "$picNum" == "0" ]; then
		process="  0%"
	else
		# process=`echo | gawk '{printf int('$picNum'/'$maxPics'*100)}'`
# ersetzt mit schnellerer Methode
		process=`expr "$picNum" \* 100 / "$maxPics"`
		if (( "$process" < "10" )); then
			process="  $process%"
		elif (( "$process" < "100" )); then
			process=" $process%"
		else
			process="$process%"
		fi
	fi

	echo "[$process] Bearbeite $name"

	return 0
}

getName () {
	if [ -z "$1" ]                           # Is parameter #1 zero length?
	then
		return 1
	fi

	pfad="${1-$DEFAULT}"

	if [ -z "$2" ]                           # Is parameter #2 zero length?
	then
		return 1
	fi

	image="${2-$DEFAULT}"

	# echo "$(basename "$pfad")"
	# var=`python -c "import os.path; print os.path.relpath('$pfad', '$image')"`
	var="${image:${#pfad}}" # Soviele Buchstaben wie die Laenge des Pfades am Anfang des Pfades des Bildes wegnehmen -> Bildname bzw. Pfad am angegeben Pfad bleibt uebrig
	echo "$var"

	return 0
}

askIfSure () {
	while true; do
		read -p "Bist du sicher, dass du die Originaldateien ueberschreiben willst? [y/n]: " yn
		case "$yn" in
			[Yy]* ) echo "1"; break;;
			[Nn]* ) echo "0"; break;;
			* ) echo "2"; break;;
		esac
	done
}

quelle="$PWD" # Aktiven Verzeichnispfad bekommen
quelleName=$(basename "$quelle")
ziel="$(readlink -f $(readlink -f $quelle)/../${quelleName}_compressed)"
#TODO pruefen, ob man Rechte ueber den Oberordner hat
maxBildGroesse="300000"
override="0"
add="0"

# schalter initialisieren
while getopts ":q:z:g:aoth" opt; do
  case "$opt" in
	h) # Help
		echo "--- Hilfe ---" >&2
		echo "" >&2
		echo "Beschreibung:" >&2
		echo -e "\tReduziert die Dateigroesse von .jpg Bildern" >&2
		echo "" >&2
		echo "Parameter:" >&2
		echo -e "\t-q /Pfad/zur/Quelle" >&2
		echo -e "\t\tQuellenpfad; Standartpfad: aktuelles_Verzeichnis" >&2
		echo -e "\t-z /Pfad/zum/Ziel" >&2
		echo -e "\t\tZielpfad; Standartpfad: aktuelles_Verzeichnis/compressed" >&2
		echo -e "\t-g GanzZahl" >&2
		echo -e "\t\tmaximale Dateigroesse in Bytes; Standartwert: 300000" >&2
		echo -e "\t-o\tUeberschreibt bereits vorhandene Dateien" >&2
		echo -e "\t-a\tFuegt noch nicht vorhandene Dateien hinzu" >&2
		echo -e "\t-h\tDiese Hilfe" >&2
		exit 2 # exit mit Hinweis 2 = nur Info
	  ;;
    q) # Quellenpfad
      quelle="$OPTARG"
      if ! [ -d "$quelle" ]; then
		echo "Der angegebene Quellpfad existiert nicht!" >&2
		exit 1
      fi
      ;;
    z) # Zielpfad
	  ziel="$OPTARG"
	  ;;
	g) # maximale Dateigroesse
	  if ! [[ "$OPTARG" =~ ^[0-9]+$ ]]; then # ueberpruefung ob Eingabe ein Integer ist
		echo "Die maximale Dateigroesse muss eine ganze positive Zahl sein" >&2
		exit 1
	  fi
	  if (( "$OPTARG" >= "50000" )); then # ueberpruefung ob Eingabe groesser als 50000 ist (50k)
		maxBildGroesse="$OPTARG"
	  fi
	  ;;
	o) # Override
	  override="1"
	  ;;
	a) # Add
	  add="1"
	  ;;
	t) # Text -> Anleitung
		echo "--- Anleitung ---" >&2
		echo "" >&2
		echo -e "Um alle Bilder eines Ordners zu komprimieren, gibt es folgende Moeglichkeiten:" >&2
		echo -e "1.\t 'gym_compress -q [QUELLE] -z [ZIEL]': Der Zielordner darf nicht existieren bzw. Dateien enthalten!" >&2
		echo -e "2.\t 'gym_compress -q [QUELLE] -z [ZIEL] -o': Alle Dateien im Zielordner werden überschrieben (also auch bereits vorhandene)." >&2
		echo -e "3.\t 'gym_compress -q [QUELLE] -z [ZIEL] -a': Alle Dateien, die noch nicht im Zielordner existieren, werden hinzugefuegt." >&2
		echo -e "4.\t 'gym_compress -q [QUELLE] -z [ZIEL]': Wenn der Zielordner auch der Quellordner ist, wird ein Zwischenspeicher erstellt." >&2
		echo -e "\t Dieser Zwischenspeicher wird am Ende alle Dateien im Quellordner ueberschreiben." >&2
		echo -e "5.\t 'gym_compress': In dem Ordner, in dem Sie sich momentan befinden, werden ALLE .jpg, .jpeg sowie .png Bilder gesucht und in gleicher Struktur in einem Ordner außerhalb des momentanen Ordners angelegt. Dessen Namen wird mit '_compressed' enden." >&2
		echo "" >&2
		exit 2 # exit mit Hinweis 2 = nur Info
	  ;;
    \?)
      echo "Unbekannter Schalter: -$OPTARG" >&2
      exit 1
      ;;
  esac
done

# update vars
quelleName=$(basename "$quelle")
ziel="$(readlink -f $ziel)"
quelle="$(readlink -f $quelle)"
if [ "$override" == "1" ] && [ "$add" == "1" ]; then
	add=0
fi

if ! [ -d "$ziel" ]; then
	if ! mkdir -p "$ziel"; then
		echo "Keine Berechtigung zum Anlegen des Ordners '$(readlink -f $ziel)'!" >&2
		exit 1
	fi
else
	if [ "$(ls -A $ziel)" ] && [ "$ziel" != "$quelle" ] && [ "$override" == "0" ] && [ "$add" == "0" ]; then # checken, ob Ordner nicht leer ist bzw das Komprimieren nicht im gleichen Ordner stattfindet
		echo "[INFO] Der Zielordner '$(readlink -f $ziel)' existiert bereits! Bitte einen noch nicht existierenden Ordner angeben (-z [NEUER_ORDNER_NAME])." >&2
		echo "[INFO] Du kannst den Ordner beibehalten, wenn du die Parameter '-o' oder '-a' benutzt." >&2
		echo "[INFO] Du kannst auch den Zielordner manuell mit 'rm -rf $(readlink -f $ziel)' loeschen und den Befehl zum komprimieren erneut ausfuehren..."
		exit 1
	fi
fi

rename 's/\s/-/g' * # Alle Dateien (*) mit Leerzeichen im Namen mit Minus ersetzen
cacheFolder="unset"

groesse=`expr "$maxBildGroesse" / 1000`
kb="kB"
groesse="$groesse$kb"

# Zwischenspeicher erstellen, falls der Quellordner der gleiche Ordner wie der Zielordner ist
zielName=$(basename "$ziel")
result=$(find "$quelle" -type d -name "$zielName")
if [ "$ziel" == "$quelle" ]; then
	if [ "$override" == "1" ] || [ $(askIfSure) == "1" ]; then
		echo "[INFO] Es wird ein Zwischenspeicher (Cache) erstellt. Dieser wird automatisch geloescht..." >&2
		if [ "$add" == "1" ]; then
			echo "[INFO] Alle neuen Dateien aus dem Ordner '$(readlink -f $quelle)' werden im Zielordner '$(readlink -f $ziel)' auf maximal $groesse herunterkomprimiert..." >&2
		else
			echo "[INFO] Alle Dateien werden im gleichem Ordner '$(readlink -f $quelle)' auf maximal $groesse herunterkomprimiert..." >&2
		fi
		echo "" >&2
		DATE=`date +%Y-%m-%d:%H:%M:%S`
		if ! mkdir -p "compress_copy_pictures_$DATE"; then
			echo "Keine Berechtigung zum Anlegen eines Ordners!" >&2
			exit 1
		else
			cacheFolder="compress_copy_pictures_$DATE"
		fi
	else
		exit 1;
	fi
elif [[ -n "$result" ]]; then
	echo "[INFO] Der Zielordner '$(readlink -f $ziel)' darf nicht in dem Quellordner '$(readlink -f $quelle)' sein..." >&2
	echo "" >&2
	exit 1;
else
	if [ "$add" == "1" ]; then
		echo "[INFO] Alle neuen Dateien aus dem Ordner '$(readlink -f $quelle)' werden im Zielordner '$(readlink -f $ziel)' auf maximal $groesse herunterkomprimiert..." >&2
	else
		echo "[INFO] Alle Dateien werden im Zielordner '$(readlink -f $ziel)' auf maximal $groesse herunterkomprimiert..." >&2
	fi
	echo "" >&2
fi

currentProcess="0";

process="  0%"
picNum="0"
maxPics="0"

# find Parameter in Variable 'matcher' speichern
matcher=( -name '*.jpg' -or -name '*.JPG' -or -name '*.png' -or -name '*.PNG' -or -name '*.jpeg' -or -name '*.JPEG' ) # Alle .jpg, .JPG, .png, .PNG und .jpeg, .JPEG aus den Ordnern bekommen (mit Unterordnern)

# auf find Parameter aus Variable 'matcher' zugreifen
for image in $(find "$quelle" "${matcher[@]}")
do
	if [ "$add" == "1" ]; then
		name="$(getName $quelle $image)"
		if ! [ -f "$ziel/$name" ]; then
			maxPics=`expr "$maxPics" + 1`
		fi
	else
		maxPics=`expr "$maxPics" + 1`
	fi
done

#for image in $quelle/*.jpg
# auf find Parameter aus Variable 'matcher' zugreifen
for image in $(find "$quelle" "${matcher[@]}")
do
	if [ -f "$image" ]; then
		name="$(getName $quelle $image)"
		if ! [ -f "$ziel/$name" ] || [ "$override" == "1" ] || [ "$add" == "1" ] || [ "$cacheFolder" != "unset" ]; then
			folder="unset"
			exists="0"
			if [ -f "$ziel/$name" ] && [ "$quelle" != "$ziel" ]; then
				exists="1"
			fi
			
			if [ "$cacheFolder" != "unset" ]; then
				tmp="$cacheFolder/$name" # Pfad bekommen
				tmpName=$(basename "$name") # Dateinamen bekommen
				length=`expr "${#tmp}" - "${#tmpName}"` # Laenge des Pfades ab Quellordner bekommen
#TODO checken, ob Ordner erstellt wurde bzw. bereits existieren
				mkdir -p "${tmp:0:$length}" # Ordner erstellen, die den Pfad ab Quellordner ohne Dateinamen haben
				cp "$image" "$cacheFolder/$name"
				folder="$cacheFolder"
			elif [ "$override" == "1" ] && [ -f "$ziel/$name" ] || ! [ -f "$ziel/$name" ]; then
				tmp="$ziel/$name"
				tmpName=$(basename "$name")
				length=`expr "${#tmp}" - "${#tmpName}"`
#TODO checken, ob Ordner erstellt wurde bzw. bereits existieren
				mkdir -p "${tmp:0:$length}"
				cp "$image" "$ziel/$name"
				folder="$ziel"
			fi
			
			if [ "$folder" != "unset" ]; then
				percent=100
				getProcess "$picNum" "$maxPics" "$name"
				while [ $(wc -c <"$folder/$name") -gt "$maxBildGroesse" ]; do
					percent=`expr "$percent" - 5`
					if (( "$percent" <= "0" )); then
						originalSize=$(wc -c <"$image")
						currentSize=$(wc -c <"$folder/$name")
						echo "[INFO] Das Bild '$image' konnte nicht unter $groesse  komprimiert werden (Groesse: $originalSize -> $currentSize)..." >&2
						break;
					fi
					convert "$image" -quality "$percent" "$folder/$name"
				done
			fi
		elif [ "$add" == "0" ]; then
			getProcess "$picNum" "$maxPics" "$name"
			echo "[INFO] Bild '$ziel/$name' existiert bereits. Zum Überschreiben den Parameter '-o' benutzen." >&2
		fi
		if [ "$exists" == "0" ] && [ "$add" == "1" ] || [ "$add" == "0" ]; then
			picNum=`expr "$picNum" + 1`
		fi
	fi
done

if [ "$cacheFolder" != "unset" ]; then
	echo "[....] kopiere Dateien aus dem Cache in den Originalordner..." >&2
# Alle Bilder aus dem Zwischenspeicher zur Quelle zurückkopieren
	for image in $(find "$cacheFolder" "${matcher[@]}")
	do
		name=$(getName "$cacheFolder" "$image")
		if [ -f "$quelle/$name" ]; then
			rm "$quelle/$name"
		fi

		cp "$image" "$quelle/$name"
	done

# Zwischenspeicher löschen
	echo "[....] loesche den Cache..." >&2
	if ! rm -rf "$cacheFolder"; then
		echo "[ERROR] Keine Berechtigung zum Löschen des Zwischenspeichers (Ordner) $cacheFolder!" >&2
		echo "[INFO] Dennoch wurden alle Dateien komprimiert. Ordner bitte manuell löschen!" >&2
		exit 1
	fi
fi

echo "[100%] Fertig!" >&2
echo "" >&2

exit 0
