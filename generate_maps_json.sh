#!/bin/bash

cd "/Users/coyle/Documents/Coding Projects/survey_map_flutter"

echo '{' > assets/building_maps.json
echo '  "maps": [' >> assets/building_maps.json

first=true
for building_dir in "Current Maps"/*; do
  if [ -d "$building_dir" ]; then
    building=$(basename "$building_dir")
    for pdf in "$building_dir"/*.pdf; do
      if [ -f "$pdf" ]; then
        room=$(basename "$pdf" .pdf)
        
        if [ "$first" = true ]; then
          first=false
        else
          echo ',' >> assets/building_maps.json
        fi
        
        echo -n "    {\"building\": \"$building\", \"room\": \"$room\", \"path\": \"$pdf\"}" >> assets/building_maps.json
      fi
    done
  fi
done

echo '' >> assets/building_maps.json
echo '  ]' >> assets/building_maps.json
echo '}' >> assets/building_maps.json

echo "Generated building_maps.json with map metadata"
