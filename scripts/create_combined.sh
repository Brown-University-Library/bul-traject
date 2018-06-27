#!/bin/sh
#
# Combines the small MARC files produced by Sierra into larger
# files to import into Solr via Traject.

MARC_FILES_PATH=/Users/hectorcorrea/dev/marc_files_jun25
COMBINED_PATH=./data
FILE_COUNT=0
BATCH_COUNT=1
BATCH_SIZE=100

echo "Deleting previous files..."
rm $COMBINED_PATH/combined_*.mrc

for FILE in `find $MARC_FILES_PATH -name "*.mrc"`
do

  FILE_TYPE=$(file -b $FILE)
  if [[ "$FILE_TYPE" == "MARC21 Bibliographic" || "$FILE_TYPE" == "data" ]]; then

    if [ "$FILE_COUNT" -eq "$BATCH_SIZE" ]; then
      BATCH_COUNT=$((BATCH_COUNT + 1))
      FILE_COUNT=1
    else
      FILE_COUNT=$((FILE_COUNT + 1))
    fi

    COMBINED_FILE="$COMBINED_PATH/combined_$BATCH_COUNT.mrc"

    echo "Processing $FILE"
    if [ "$FILE_COUNT" -eq 1 ]; then
      cat $FILE > $COMBINED_FILE
    else
      cat $FILE >> $COMBINED_FILE
    fi

  else
    # Skip empty files and files with JSON content
    echo "Skipping $FILE $FILE_TYPE"
  fi

done

echo "Done creating combined files"
