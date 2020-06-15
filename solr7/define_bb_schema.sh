#!/bin/bash
# IMPORTANT: In production this script must be executed as the application user

# exit upon error
set -e

# == UPDATE THESE FOR PRODUCTION ==
SOLR_CORE="bestbets7"
SOLR_PORT="8983"
SOLR_EXE=/Users/hectorcorrea/solr-7.5.0/bin/solr
SOLR_CONF_PATH="/Users/hectorcorrea/solr-7.5.0/server/solr/$SOLR_CORE/conf"

# Required for Solr to use the newer version of java
# export SOLR_JAVA_HOME="/etc/alternatives/jre_openjdk"
#
# =================================

SOLR_CORE_URL="http://localhost:$SOLR_PORT/solr/$SOLR_CORE"
SOLR_RELOAD_URL="http://localhost:$SOLR_PORT/solr/admin/cores?action=RELOAD&core=$SOLR_CORE"

# ====================
# Recreate the Solr core
# ====================
echo "Recreating core: $SOLR_CORE_URL ..."
# $SOLR_EXE delete -c $SOLR_CORE -p $SOLR_PORT
$SOLR_EXE create -c $SOLR_CORE -p $SOLR_PORT
$SOLR_EXE config -c $SOLR_CORE -p $SOLR_PORT -action set-user-property -property update.autoCreateFields -value false


# ====================
# Fields
# ====================
echo "Defining fields..."

curl -X POST -H 'Content-type:application/json' --data-binary '{
  "add-field":{
    "name":"name_display",
    "type":"string",
    "stored":true,
    "indexed":true
  }
}' $SOLR_CORE_URL/schema

curl -X POST -H 'Content-type:application/json' --data-binary '{
  "add-field":{
    "name":"url_display",
    "type":"string",
    "stored":true,
    "indexed":true
  }
}' $SOLR_CORE_URL/schema

curl -X POST -H 'Content-type:application/json' --data-binary '{
  "add-field":{
    "name":"description_display",
    "type":"string",
    "stored":true,
    "indexed":false
  }
}' $SOLR_CORE_URL/schema

curl -X POST -H 'Content-type:application/json' --data-binary '{
  "add-field":{
    "name":"term",
    "type":"string",
    "stored":false,
    "indexed":true,
    "multiValued":true
  }
}' $SOLR_CORE_URL/schema
