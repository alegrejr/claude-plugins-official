#!/bin/bash

DOWNLOADS="${1:-$HOME/Downloads}"

if [ ! -d "$DOWNLOADS" ]; then
  echo "No se encontró la carpeta: $DOWNLOADS"
  exit 1
fi

declare -A CATEGORIES=(
  ["Imagenes"]="jpg jpeg png gif bmp svg webp ico tiff"
  ["Videos"]="mp4 mkv avi mov wmv flv webm m4v"
  ["Audio"]="mp3 wav flac aac ogg m4a wma"
  ["Documentos"]="pdf doc docx txt odt rtf md"
  ["Hojas_de_Calculo"]="xls xlsx csv ods"
  ["Presentaciones"]="ppt pptx odp"
  ["Comprimidos"]="zip tar gz rar 7z bz2 xz"
  ["Instaladores"]="exe msi dmg pkg deb rpm appimage"
  ["Codigo"]="py js ts html css json xml yaml yml sh bash java c cpp h"
  ["Torrents"]="torrent"
)

moved=0
skipped=0

for file in "$DOWNLOADS"/*; do
  [ -f "$file" ] || continue

  filename=$(basename "$file")
  ext="${filename##*.}"
  ext=$(echo "$ext" | tr '[:upper:]' '[:lower:]')

  [ "$ext" = "$filename" ] && { ((skipped++)); continue; }

  dest_folder=""
  for category in "${!CATEGORIES[@]}"; do
    if echo "${CATEGORIES[$category]}" | grep -qw "$ext"; then
      dest_folder="$DOWNLOADS/$category"
      break
    fi
  done

  [ -z "$dest_folder" ] && dest_folder="$DOWNLOADS/Otros"

  mkdir -p "$dest_folder"

  if [ -e "$dest_folder/$filename" ]; then
    base="${filename%.*}"
    dest_file="$dest_folder/${base}_$(date +%s).$ext"
  else
    dest_file="$dest_folder/$filename"
  fi

  mv "$file" "$dest_file"
  echo "  $filename -> $(basename $dest_folder)/"
  ((moved++))
done

echo ""
echo "Listo: $moved archivos organizados, $skipped sin extension ignorados."
