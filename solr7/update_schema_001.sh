#!/bin/bash
# Allows for multi-value CJK fields

# == UPDATE THESE FOR PRODUCTION ==
SOLR_CORE="josiah7"
SOLR_PORT="8983"
# =================================

SOLR_CORE_URL="http://localhost:$SOLR_PORT/solr/$SOLR_CORE"
SOLR_RELOAD_URL="http://localhost:$SOLR_PORT/solr/admin/cores?action=RELOAD&core=$SOLR_CORE"


# CJK support
echo "Adding new CJK fields..."
curl -X POST -H 'Content-type:application/json' --data-binary '{
  "add-field":{
    "name":"author_txt_cjk",
    "type":"text_cjk",
    "multiValued":true
  }
}' $SOLR_CORE_URL/schema

curl -X POST -H 'Content-type:application/json' --data-binary '{
  "add-field":{
    "name":"title_txt_cjk",
    "type":"text_cjk",
    "multiValued":true
  }
}' $SOLR_CORE_URL/schema


echo "Reloading Solr core..."
curl "$SOLR_RELOAD_URL"
