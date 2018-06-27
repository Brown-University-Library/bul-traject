#!/bin/sh
#
# Imports the combined files created by create_combined.#!/bin/sh
SOLR_URL=http://localhost:8081/solr/blacklight-core

echo "Started importing at echo $(date)"

# echo "Deleting all Solr documents..."
# curl "$SOLR_URL/update?commit=true" \
# -H "Content-Type: text/xml" \
# --data-binary '<delete><query>*:*</query></delete>'

for FILE in `ls -m1 ./data/combined_*.mrc`
do
  echo "Processing $FILE"
  traject -c config.rb -u $SOLR_URL $FILE
  curl $SOLR_URL/update?commit=true
done

echo "Done importing at $(date)"
