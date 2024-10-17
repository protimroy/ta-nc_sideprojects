#!/bin/bash

# get the train dir from the command line
TRAIN_DIR=$1

# Iterate over each .v file in the train directory
for FILE in "$TRAIN_DIR"/*.v; 
do
    # get the module name from the file
    MODULE=$(grep -m 1 -oP '(?<=module\s)\w+' "$FILE")

    # Extract the base name of the file (without directory and extension)
    BASENAME=$(basename "$FILE" .v)

    #check if "${BASENAME}_tb.v" exists, if so then continue to next file
    if [ -f "${BASENAME}_tb.v" ]; then
        continue
    fi
    
    # Run the gentbvlog command with the appropriate parameters
    gentbvlog -in "$FILE" -top "${MODULE}" -out "${TRAIN_DIR}/${BASENAME}_tb.v" -dump -clk clk -rst reset

done