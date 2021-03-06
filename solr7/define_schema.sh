#!/bin/bash
# IMPORTANT: In production this script must be executed as the application user

# exit upon error
set -e

# == UPDATE THESE FOR PRODUCTION ==
SOLR_CORE="josiah7"
SOLR_PORT="8983"
SOLR_EXE=/Users/hectorcorrea/solr-7.5.0/bin/solr
SOLR_CONF_PATH="/Users/hectorcorrea/solr-7.5.0/server/solr/$SOLR_CORE/conf"
BASE_CONFIG_FILE=/Users/hectorcorrea/dev/bul-traject/solr7/solrconfig7.xml
BASE_SYNONYMS_FILE=/Users/hectorcorrea/dev/bul-traject/solr7/synonyms7.txt

# Required for Solr to use the newer version of java
# export SOLR_JAVA_HOME="/etc/alternatives/jre_openjdk"
#
# =================================

SOLR_CORE_URL="http://localhost:$SOLR_PORT/solr/$SOLR_CORE"
SOLR_RELOAD_URL="http://localhost:$SOLR_PORT/solr/admin/cores?action=RELOAD&core=$SOLR_CORE"

SOLR_CONFIG_XML="$SOLR_CONF_PATH/solrconfig.xml"
STOPWORDS_FILE="$SOLR_CONF_PATH/stopwords.txt"
STOPWORDS_EN_FILE="$SOLR_CONF_PATH/lang/stopwords_en.txt"
SYNONYMS_FILE="$SOLR_CONF_PATH/synonyms.txt"


# ====================
# Recreate the Solr core and update the solrconfig.xml file
# ====================
echo "Recreating core: $SOLR_CORE_URL ..."
$SOLR_EXE delete -c $SOLR_CORE -p $SOLR_PORT
$SOLR_EXE create -c $SOLR_CORE -p $SOLR_PORT
$SOLR_EXE config -c $SOLR_CORE -p $SOLR_PORT -action set-user-property -property update.autoCreateFields -value false

echo "Updating config files..."
echo "$SOLR_RELOAD_URL"

# Our custom solrconfig to mimic Solr 4 behavior that Blacklight needs
cp $BASE_CONFIG_FILE $SOLR_CONFIG_XML

# Use english stop words for text_general fields (to behave like our Solr 4 instance did)
cp $STOPWORDS_EN_FILE $STOPWORDS_FILE

# Use our custom synonyms file
cp $BASE_SYNONYMS_FILE $SYNONYMS_FILE

echo "Loading new config..."
curl "$SOLR_RELOAD_URL"


# ====================
# Field types
# ====================
echo "Defining new types..."

curl -X POST -H 'Content-type:application/json' --data-binary '{
  "add-field-type" : {
     "name":"alphaOnlySort",
     "class":"solr.TextField",
     "sortMissingLast":"true",
     "omitNorms":"true",
     "analyzer" : {
        "tokenizer":{"class":"solr.KeywordTokenizerFactory"},
        "filters":[
          { "class":"solr.LowerCaseFilterFactory" },
          { "class":"solr.TrimFilterFactory" },
          {
            "class":"solr.PatternReplaceFilterFactory",
            "pattern":"([^a-z])",
            "replacement":"",
            "replace":"all"
          }
      ]
    }
  }
}' $SOLR_CORE_URL/schema

curl -X POST -H 'Content-type:application/json' --data-binary '{
  "add-field-type" : {
     "name":"textSpell",
     "class":"solr.TextField",
     "sortMissingLast":"true",
     "multiValued":true,
     "omitNorms":"true",
     "analyzer" : {
        "tokenizer":{"class":"solr.KeywordTokenizerFactory"},
        "filters":[
          {
            "class":"solr.StopFilterFactory",
            "words":"stopwords.txt",
            "ignoreCase": "true"
          },
          { "class":"solr.LowerCaseFilterFactory" },
          { "class":"solr.RemoveDuplicatesTokenFilterFactory" },
          { "class":"solr.SnowballPorterFilterFactory" }
      ]
    }
  }
}' $SOLR_CORE_URL/schema


# This field type is used to emulate the "text" field in Solr 4 that
# included the ICUFoldingFilterFactory and SnowballPorterFilterFactory
# filters.
#
# Don't omitNorms for this field.
# See https://stackoverflow.com/questions/29103155/solr-exact-match-boost-over-text-containing-the-exact-match
#
curl -X POST -H 'Content-type:application/json' --data-binary '{
  "add-field-type" : {
     "name":"text_search",
     "class":"solr.TextField",
     "positionIncrementGap":"100",
     "multiValued":true,
     "sortMissingLast":"true",
     "indexAnalyzer" : {
        "tokenizer":{"class":"solr.StandardTokenizerFactory"},
        "filters":[
          {
            "class":"solr.ICUFoldingFilterFactory"
          },
          {
            "class":"solr.StopFilterFactory",
            "words":"stopwords.txt",
            "ignoreCase": "true"
          },
          {
            "class":"solr.SnowballPorterFilterFactory"
          }
      ]
    },
    "queryAnalyzer" : {
        "tokenizer":{"class":"solr.StandardTokenizerFactory"},
        "filters":[
          {
            "class":"solr.ICUFoldingFilterFactory"
          },
          {
            "class":"solr.SynonymGraphFilterFactory",
            "expand": "true",
            "synonyms": "synonyms.txt",
            "ignoreCase": "true"
          },
          {
            "class":"solr.StopFilterFactory",
            "words":"stopwords.txt",
            "ignoreCase": "true"
          },
          {
            "class":"solr.SnowballPorterFilterFactory"
          }
      ]
    }
  }
}' $SOLR_CORE_URL/schema


# Similar to text_search but we don't use stemming.
#
# Note: As a future enhancement we can also drop the StopFilterFactory
# but that affects search results significantly -- we'll evaluate this
# after the Solr 7 migration.
curl -X POST -H 'Content-type:application/json' --data-binary '{
  "add-field-type" : {
     "name":"text_unstem_search",
     "class":"solr.TextField",
     "positionIncrementGap":"100",
     "multiValued":true,
     "sortMissingLast":"true",
     "indexAnalyzer" : {
        "tokenizer": {"class":"solr.StandardTokenizerFactory"},
        "filters":[
          { "class":"solr.LowerCaseFilterFactory" },
          { "class":"solr.StopFilterFactory", "words":"stopwords.txt", "ignoreCase": "true" },
          { "class":"solr.ICUFoldingFilterFactory" }
        ]
    },
    "queryAnalyzer" : {
        "tokenizer":{"class":"solr.StandardTokenizerFactory"},
        "filters":[
          { "class":"solr.LowerCaseFilterFactory" },
          { "class":"solr.ICUFoldingFilterFactory" },
          { "class":"solr.StopFilterFactory", "words":"stopwords.txt", "ignoreCase": "true" },
          { "class":"solr.SynonymGraphFilterFactory", "expand": "true", "synonyms": "synonyms.txt", "ignoreCase": "true" }
        ]
    }
  }
}' $SOLR_CORE_URL/schema

# Similar to text_search but we don't use stemming or stop words.
curl -X POST -H 'Content-type:application/json' --data-binary '{
  "add-field-type" : {
     "name":"text_strict_search",
     "class":"solr.TextField",
     "positionIncrementGap":"100",
     "multiValued":true,
     "sortMissingLast":"true",
     "indexAnalyzer" : {
        "tokenizer": {"class":"solr.StandardTokenizerFactory"},
        "filters":[
          { "class":"solr.LowerCaseFilterFactory" },
          { "class":"solr.ICUFoldingFilterFactory" }
        ]
    },
    "queryAnalyzer" : {
        "tokenizer":{"class":"solr.StandardTokenizerFactory"},
        "filters":[
          { "class":"solr.LowerCaseFilterFactory" },
          { "class":"solr.ICUFoldingFilterFactory" },
          { "class":"solr.SynonymGraphFilterFactory", "expand": "true", "synonyms": "synonyms.txt", "ignoreCase": "true" }
        ]
    }
  }
}' $SOLR_CORE_URL/schema

# Similar to text_search but we don't use stemming or stop words
# and we use the keyword tokenizer to try to boost exact matches.
# Not used because it causes issues with multi-word searches.
curl -X POST -H 'Content-type:application/json' --data-binary '{
  "add-field-type" : {
     "name":"text_strict_key_search",
     "class":"solr.TextField",
     "positionIncrementGap":"100",
     "multiValued":true,
     "sortMissingLast":"true",
     "indexAnalyzer" : {
        "tokenizer": {"class":"solr.KeywordTokenizerFactory"},
        "filters":[
          { "class":"solr.LowerCaseFilterFactory" },
          { "class":"solr.ICUFoldingFilterFactory" }
        ]
    },
    "queryAnalyzer" : {
        "tokenizer":{"class":"solr.KeywordTokenizerFactory"},
        "filters":[
          { "class":"solr.LowerCaseFilterFactory" },
          { "class":"solr.ICUFoldingFilterFactory" },
          { "class":"solr.SynonymGraphFilterFactory", "expand": "true", "synonyms": "synonyms.txt", "ignoreCase": "true" }
        ]
    }
  }
}' $SOLR_CORE_URL/schema


# ====================
# Fields
#
# Notice that we specifically define several fields to be different
# from what the dynamic field definitions would do (e.g. set some
# *_display fields as single value) so that we are compatible with
# the schema that we are migrating from.
# ====================
echo "Defining fields..."

# Notice that the core must be reloaded for this field (that has a default value)
# to be registered and become effective. See note at the bottom of this script.
curl -X POST -H 'Content-type:application/json' --data-binary '{
  "add-field":{
    "name":"timestamp",
    "type":"pdate",
    "default":"NOW",
    "multiValued":false,
    "stored":true,
    "indexed":true
  }
}' $SOLR_CORE_URL/schema

# Notice that we map "text" to "text_search" to preserve Solr 4's
# compatibility.
curl -X POST -H 'Content-type:application/json' --data-binary '{
  "add-field":{
    "name":"text",
    "type":"text_search",
    "multiValued":true,
    "stored":false,
    "indexed":true
  }
}' $SOLR_CORE_URL/schema

curl -X POST -H 'Content-type:application/json' --data-binary '{
  "add-field":{
    "name":"format",
    "type":"string",
    "stored":true,
    "indexed":true
  }
}' $SOLR_CORE_URL/schema

# Why is this multi-value? (if pub_date_sort is single value)
curl -X POST -H 'Content-type:application/json' --data-binary '{
  "add-field":{
    "name":"pub_date",
    "type":"strings",
    "stored":true,
    "indexed":true
  }
}' $SOLR_CORE_URL/schema

curl -X POST -H 'Content-type:application/json' --data-binary '{
  "add-field":{
    "name":"pub_date_sort",
    "type":"pint",
    "multiValued":false,
    "stored":true,
    "indexed":true
  }
}' $SOLR_CORE_URL/schema

curl -X POST -H 'Content-type:application/json' --data-binary '{
  "add-field":{
    "name":"subject_t",
    "type":"text_search",
    "multiValued":true,
    "stored":true,
    "indexed":true
  }
}' $SOLR_CORE_URL/schema

curl -X POST -H 'Content-type:application/json' --data-binary '{
  "add-field":{
    "name":"author_addl_t",
    "type":"text_search",
    "multiValued":true,
    "stored":true,
    "indexed":true
  }
}' $SOLR_CORE_URL/schema

curl -X POST -H 'Content-type:application/json' --data-binary '{
  "add-field":{
    "name":"title_series_t",
    "type":"text_search",
    "multiValued":true,
    "stored":true,
    "indexed":true
  }
}' $SOLR_CORE_URL/schema

curl -X POST -H 'Content-type:application/json' --data-binary '{
  "add-field":{
    "name":"title_t",
    "type":"text_search",
    "multiValued":true,
    "stored":true,
    "indexed":true
  }
}' $SOLR_CORE_URL/schema

curl -X POST -H 'Content-type:application/json' --data-binary '{
  "add-field":{
    "name":"author_t",
    "type":"text_search",
    "multiValued":true,
    "stored":true,
    "indexed":true
  }
}' $SOLR_CORE_URL/schema

curl -X POST -H 'Content-type:application/json' --data-binary '{
  "add-field":{
    "name":"callnumber_t",
    "type":"text_general",
    "multiValued":true,
    "stored":true,
    "indexed":true
  }
}' $SOLR_CORE_URL/schema

# Shouldn't this be strings?
curl -X POST -H 'Content-type:application/json' --data-binary '{
  "add-field":{
    "name":"oclc_t",
    "type":"text_general",
    "multiValued":true,
    "stored":true,
    "indexed":true
  }
}' $SOLR_CORE_URL/schema

# Shouldn't this be strings?
curl -X POST -H 'Content-type:application/json' --data-binary '{
  "add-field":{
    "name":"isbn_t",
    "type":"text_general",
    "multiValued":true,
    "stored":true,
    "indexed":true
  }
}' $SOLR_CORE_URL/schema

# Shouldn't this be strings?
curl -X POST -H 'Content-type:application/json' --data-binary '{
  "add-field":{
    "name":"issn_t",
    "type":"text_general",
    "multiValued":true,
    "stored":true,
    "indexed":true
  }
}' $SOLR_CORE_URL/schema

curl -X POST -H 'Content-type:application/json' --data-binary '{
  "add-field":{
    "name":"location_code_t",
    "type":"text_general",
    "multiValued":true,
    "stored":true,
    "indexed":true
  }
}' $SOLR_CORE_URL/schema

# Must be single value
curl -X POST -H 'Content-type:application/json' --data-binary '{
  "add-field":{
    "name":"author_display",
    "type":"string",
    "stored":true,
    "indexed":false
  }
}' $SOLR_CORE_URL/schema

# Must be single value
curl -X POST -H 'Content-type:application/json' --data-binary '{
  "add-field":{
    "name":"published_vern_display",
    "type":"strings",
    "stored":true,
    "indexed":false
  }
}' $SOLR_CORE_URL/schema

# Must be single value
curl -X POST -H 'Content-type:application/json' --data-binary '{
  "add-field":{
    "name":"title_display",
    "type":"string",
    "stored":true,
    "indexed":false
  }
}' $SOLR_CORE_URL/schema

# Must be single value
curl -X POST -H 'Content-type:application/json' --data-binary '{
  "add-field":{
    "name":"title_vern_display",
    "type":"string",
    "stored":true,
    "indexed":false
  }
}' $SOLR_CORE_URL/schema

# docValues=false allows to store more than 32K in the field, otherwise
# we get error: "DocValuesField marc_display is too large, must be <= 32766"
curl -X POST -H 'Content-type:application/json' --data-binary '{
  "add-field":{
    "name":"marc_display",
    "type":"string",
    "multiValued":false,
    "stored":true,
    "indexed":false,
    "docValues":false
  }
}' $SOLR_CORE_URL/schema

# docValues=false allows to store more than 32K in the field, otherwise
# we get error: "DocValuesField toc_display is too large, must be <= 32766"
#
# TODO: should this be indexed? I think it is indexed through "text" field
# combined directly in Traject.
#
# See also field toc_970_display below.
curl -X POST -H 'Content-type:application/json' --data-binary '{
  "add-field":{
    "name":"toc_display",
    "type":"strings",
    "stored":true,
    "indexed":false,
    "docValues":false
  }
}' $SOLR_CORE_URL/schema

curl -X POST -H 'Content-type:application/json' --data-binary '{
  "add-field":{
    "name":"toc_970_display",
    "type":"strings",
    "stored":true,
    "indexed":false,
    "docValues":false
  }
}' $SOLR_CORE_URL/schema

# docValues=false allows to store more than 32K in the field
curl -X POST -H 'Content-type:application/json' --data-binary '{
  "add-field":{
    "name":"uniform_related_works_display",
    "type":"strings",
    "stored":true,
    "indexed":false,
    "docValues":false
  }
}' $SOLR_CORE_URL/schema


# CJK support
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


# ====================
# Dynamic fields
# ====================
echo "Defining dynamic fields..."

curl -X POST -H 'Content-type:application/json' --data-binary '{
  "add-dynamic-field":{
    "name":"*_display",
    "type":"strings",
    "stored":true,
    "indexed":false
  }
}' $SOLR_CORE_URL/schema

curl -X POST -H 'Content-type:application/json' --data-binary '{
  "add-dynamic-field":{
    "name":"*_facet",
    "type":"strings",
    "stored":false,
    "indexed": true
  }
}' $SOLR_CORE_URL/schema

curl -X POST -H 'Content-type:application/json' --data-binary '{
  "add-dynamic-field":{
    "name":"*_unstem_search",
    "type":"text_unstem_search",
    "stored":false,
    "indexed":true
  }
}' $SOLR_CORE_URL/schema

curl -X POST -H 'Content-type:application/json' --data-binary '{
  "add-dynamic-field":{
    "name":"*_strict_search",
    "type":"text_strict_search",
    "stored":false,
    "indexed":true
  }
}' $SOLR_CORE_URL/schema

curl -X POST -H 'Content-type:application/json' --data-binary '{
  "add-dynamic-field":{
    "name":"*_strict_key_search",
    "type":"text_strict_key_search",
    "stored":false,
    "indexed":true
  }
}' $SOLR_CORE_URL/schema

curl -X POST -H 'Content-type:application/json' --data-binary '{
  "add-dynamic-field":{
    "name":"*spell",
    "type":"textSpell",
    "stored":false,
    "indexed": true
  }
}' $SOLR_CORE_URL/schema

curl -X POST -H 'Content-type:application/json' --data-binary '{
  "add-dynamic-field":{
    "name":"*_sort",
    "type":"alphaOnlySort",
    "multiValued":false,
    "stored":false,
    "indexed": true
  }
}' $SOLR_CORE_URL/schema


# ====================
# Copy fields
# ====================
echo "Defining copy fields..."

curl -X POST -H 'Content-type:application/json' --data-binary '{
  "add-copy-field":{
    "source":"title_display",
    "dest":[ "title_unstem_search", "title_strict_search" ]}
}' $SOLR_CORE_URL/schema

curl -X POST -H 'Content-type:application/json' --data-binary '{
  "add-copy-field":{
    "source":"title_t",
    "dest":[ "title_other_unstem_search", "title_other_strict_search", "opensearch_display" ]}
}' $SOLR_CORE_URL/schema

curl -X POST -H 'Content-type:application/json' --data-binary '{
  "add-copy-field":{
    "source":"subtitle_t",
    "dest":[ "subtitle_other_unstem_search", "subtitle_other_strict_search", "opensearch_display" ]}
}' $SOLR_CORE_URL/schema

curl -X POST -H 'Content-type:application/json' --data-binary '{
  "add-copy-field":{
    "source":"title_series_t",
    "dest":[ "title_series_unstem_search", "title_series_strict_search", "opensearch_display" ]}
}' $SOLR_CORE_URL/schema

curl -X POST -H 'Content-type:application/json' --data-binary '{
  "add-copy-field":{
    "source":"author_t",
    "dest":[ "author_unstem_search", "author_strict_search", "opensearch_display" ]}
}' $SOLR_CORE_URL/schema

curl -X POST -H 'Content-type:application/json' --data-binary '{
  "add-copy-field":{
    "source":"author_addl_t",
    "dest":[ "author_addl_unstem_search", "author_addl_strict_search", "opensearch_display" ]}
}' $SOLR_CORE_URL/schema

curl -X POST -H 'Content-type:application/json' --data-binary '{
  "add-copy-field":{
    "source":"subject_t",
    "dest":[ "subject_unstem_search", "subject_strict_search", "opensearch_display" ]}
}' $SOLR_CORE_URL/schema

curl -X POST -H 'Content-type:application/json' --data-binary '{
  "add-copy-field":{
    "source":"subject_addl_t",
    "dest":[ "subject_addl_unstem_search", "subject_addl_strict_search", "opensearch_display" ]}
}' $SOLR_CORE_URL/schema

curl -X POST -H 'Content-type:application/json' --data-binary '{
  "add-copy-field":{
    "source":"subject_topic_facet",
    "dest":[ "subject_topic_unstem_search", "subject_topic_strict_search", "opensearch_display" ]}
}' $SOLR_CORE_URL/schema

curl -X POST -H 'Content-type:application/json' --data-binary '{
  "add-copy-field":{
    "source":"pub_date",
    "dest":[ "pub_date_sort" ]}
}' $SOLR_CORE_URL/schema

curl -X POST -H 'Content-type:application/json' --data-binary '{
  "add-copy-field":{
    "source":"*_t",
    "dest":[ "spell" ]}
}' $SOLR_CORE_URL/schema

curl -X POST -H 'Content-type:application/json' --data-binary '{
  "add-copy-field":{
    "source":"*_facet",
    "dest":[ "spell" ]}
}' $SOLR_CORE_URL/schema

curl -X POST -H 'Content-type:application/json' --data-binary '{
  "add-copy-field":{
    "source":"title_t",
    "dest":[ "title_spell" ]}
}' $SOLR_CORE_URL/schema

curl -X POST -H 'Content-type:application/json' --data-binary '{
  "add-copy-field":{
    "source":"subtitle_t",
    "dest":[ "title_spell" ]}
}' $SOLR_CORE_URL/schema

curl -X POST -H 'Content-type:application/json' --data-binary '{
  "add-copy-field":{
    "source":"addl_titles_t",
    "dest":[ "title_spell" ]}
}' $SOLR_CORE_URL/schema

curl -X POST -H 'Content-type:application/json' --data-binary '{
  "add-copy-field":{
    "source":"title_added_entry_t",
    "dest":[ "title_spell" ]}
}' $SOLR_CORE_URL/schema

curl -X POST -H 'Content-type:application/json' --data-binary '{
  "add-copy-field":{
    "source":"title_series_t",
    "dest":[ "title_spell" ]}
}' $SOLR_CORE_URL/schema

curl -X POST -H 'Content-type:application/json' --data-binary '{
  "add-copy-field":{
    "source":"author_t",
    "dest":[ "author_spell" ]}
}' $SOLR_CORE_URL/schema

curl -X POST -H 'Content-type:application/json' --data-binary '{
  "add-copy-field":{
    "source":"author_addl_t",
    "dest":[ "author_spell" ]}
}' $SOLR_CORE_URL/schema

curl -X POST -H 'Content-type:application/json' --data-binary '{
  "add-copy-field":{
    "source":"subject_topic_facet",
    "dest":[ "subject_spell" ]}
}' $SOLR_CORE_URL/schema

curl -X POST -H 'Content-type:application/json' --data-binary '{
  "add-copy-field":{
    "source":"subject_t",
    "dest":[ "subject_spell" ]}
}' $SOLR_CORE_URL/schema

curl -X POST -H 'Content-type:application/json' --data-binary '{
  "add-copy-field":{
    "source":"subject_addl_t",
    "dest":[ "subject_spell" ]}
}' $SOLR_CORE_URL/schema


# This is required so that the timestamp field takes effect
# on new documents.
# See https://stackoverflow.com/questions/37352306/add-document-insert-timestamp-to-all-documents
echo "Reloading Solr core one last time..."
curl "$SOLR_RELOAD_URL"


# ====================
# Use this to export all the *actual* fields defined in the code
# *after* importing data
#
# curl $SOLR_CORE_URL/admin/luke?numTerms=0 > luke7.xml
# ====================
