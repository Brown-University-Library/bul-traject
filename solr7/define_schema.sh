SOLR_CORE=cjkdemo
SOLR_PORT=8983
SOLR_CORE_URL=http://localhost:$SOLR_PORT/solr/$SOLR_CORE
SOLR_RELOAD_URL=http://localhost:$SOLR_PORT/solr/admin/cores?action=RELOAD&core=$SOLR_CORE
SOLR_CONFIG_XML=~/solr-7.4.0/server/solr/$SOLR_CORE/conf/solrconfig.xml

# ====================
# Recreate the Solr core
# ====================
echo "Recreating core: $SOLR_CORE_URL ..."
solr delete -c $SOLR_CORE
solr create -c $SOLR_CORE
solr config -c $SOLR_CORE -p $SOLR_PORT -action set-user-property -property update.autoCreateFields -value false

echo "Loading new config.."
cp solrconfig7.xml $SOLR_CONFIG_XML
curl $SOLR_RELOAD_URL

echo "Defining new fields..."

# ====================
# Use this to export all the *actual* fields defined in the code
# *after* importing data
#
# curl $SOLR_CORE_URL/admin/luke?numTerms=0 > luke7.xml
# ====================


# ====================
# Field types
# ====================
curl -X POST -H 'Content-type:application/json' --data-binary '{
  "add-field-type" : {
     "name":"alphaOnlySort",
     "class":"solr.TextField",
     "sortMissingLast":"true",
     "omitNorms":"true",
     "analyzer" : {
        "tokenizer":{"class":"solr.KeywordTokenizerFactory"},
        "filters":[
          {
            "class":"solr.LowerCaseFilterFactory"
          },
          {
            "class":"solr.TrimFilterFactory"
          },
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


# ====================
# Fields
#
# Notice that we specifically define several _t fields as multi-value
# to prevent them being defined by the dynamic-field definition *_t
# that comes with Solr and creates them as single-value.
# ====================
curl -X POST -H 'Content-type:application/json' --data-binary '{
  "add-field":{
    "name":"timestamp",
    "type":"pdate",
    "multiValued":false,
    "default":"NOW"
  }
}' $SOLR_CORE_URL/schema

# Notice that we map "text" to "text_en" rather than to "text_general"
# because Solr 4's "text" field behaved like "text_en" due to the
# use the SnowballFilter.
curl -X POST -H 'Content-type:application/json' --data-binary '{
  "add-field":{
    "name":"text",
    "type":"text_en",
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

curl -X POST -H 'Content-type:application/json' --data-binary '{
  "add-field":{
    "name":"pub_date",
    "type":"string",
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

# shouldn't this be strings?
curl -X POST -H 'Content-type:application/json' --data-binary '{
  "add-field":{
    "name":"isbn_t",
    "type":"text_general",
    "multiValued":true,
    "stored":true,
    "indexed":true
  }
}' $SOLR_CORE_URL/schema

curl -X POST -H 'Content-type:application/json' --data-binary '{
  "add-field":{
    "name":"subject_t",
    "type":"text_en",
    "multiValued":true,
    "stored":true,
    "indexed":true
  }
}' $SOLR_CORE_URL/schema

curl -X POST -H 'Content-type:application/json' --data-binary '{
  "add-field":{
    "name":"author_addl_t",
    "type":"text_en",
    "multiValued":true,
    "stored":true,
    "indexed":true
  }
}' $SOLR_CORE_URL/schema

curl -X POST -H 'Content-type:application/json' --data-binary '{
  "add-field":{
    "name":"title_series_t",
    "type":"text_en",
    "multiValued":true,
    "stored":true,
    "indexed":true
  }
}' $SOLR_CORE_URL/schema

curl -X POST -H 'Content-type:application/json' --data-binary '{
  "add-field":{
    "name":"title_t",
    "type":"text_en",
    "multiValued":true,
    "stored":true,
    "indexed":true
  }
}' $SOLR_CORE_URL/schema

curl -X POST -H 'Content-type:application/json' --data-binary '{
  "add-field":{
    "name":"author_t",
    "type":"text_en",
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

# Should this be string?
curl -X POST -H 'Content-type:application/json' --data-binary '{
  "add-field":{
    "name":"oclc_t",
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

# Should this be string?
curl -X POST -H 'Content-type:application/json' --data-binary '{
  "add-field":{
    "name":"issn_t",
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
    "multiValued":false,
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


# ====================
# Dynamic fields
# ====================
curl -X POST -H 'Content-type:application/json' --data-binary '{
  "add-dynamic-field":{
    "name":"*_display",
    "type":"strings",
    "stored":true,
    "indexed": false
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
    "type":"text_general",
    "stored":false,
    "indexed": true
  }
}' $SOLR_CORE_URL/schema

curl -X POST -H 'Content-type:application/json' --data-binary '{
  "add-dynamic-field":{
    "name":"*spell",
    "type":"text_general",
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
curl -X POST -H 'Content-type:application/json' --data-binary '{
  "add-copy-field":{
    "source":"title_display",
    "dest":[ "title_unstem_search" ]}
}' $SOLR_CORE_URL/schema

curl -X POST -H 'Content-type:application/json' --data-binary '{
  "add-copy-field":{
    "source":"title_t",
    "dest":[ "title_other_unstem_search", "opensearch_display" ]}
}' $SOLR_CORE_URL/schema

curl -X POST -H 'Content-type:application/json' --data-binary '{
  "add-copy-field":{
    "source":"subtitle_t",
    "dest":[ "subtitle_other_unstem_search", "opensearch_display" ]}
}' $SOLR_CORE_URL/schema

curl -X POST -H 'Content-type:application/json' --data-binary '{
  "add-copy-field":{
    "source":"title_series_t",
    "dest":[ "title_series_unstem_search", "opensearch_display" ]}
}' $SOLR_CORE_URL/schema

curl -X POST -H 'Content-type:application/json' --data-binary '{
  "add-copy-field":{
    "source":"author_t",
    "dest":[ "author_unstem_search", "opensearch_display" ]}
}' $SOLR_CORE_URL/schema

curl -X POST -H 'Content-type:application/json' --data-binary '{
  "add-copy-field":{
    "source":"author_addl_t",
    "dest":[ "author_addl_unstem_search", "opensearch_display" ]}
}' $SOLR_CORE_URL/schema

curl -X POST -H 'Content-type:application/json' --data-binary '{
  "add-copy-field":{
    "source":"subject_t",
    "dest":[ "subject_unstem_search", "opensearch_display" ]}
}' $SOLR_CORE_URL/schema

curl -X POST -H 'Content-type:application/json' --data-binary '{
  "add-copy-field":{
    "source":"subject_addl_t",
    "dest":[ "subject_addl_unstem_search", "opensearch_display" ]}
}' $SOLR_CORE_URL/schema

curl -X POST -H 'Content-type:application/json' --data-binary '{
  "add-copy-field":{
    "source":"subject_topic_facet",
    "dest":[ "subject_topic_unstem_search", "opensearch_display" ]}
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



