SOLR_CORE=cjkdemo
SOLR_CORE_URL=http://localhost:8983/solr/$SOLR_CORE

# ====================
# Recreate the Solr core
# ====================
echo "Recreating core: $SOLR_CORE_URL"
# solr delete -c $SOLR_CORE
# solr create -c $SOLR_CORE

# ====================
# Field Types
# ====================
echo "Defining types and fields..."
curl -X POST -H 'Content-type:application/json' --data-binary '{
  "add-field-type" : {
     "name":"textSpell",
     "class":"solr.TextField",
     "positionIncrementGap":"100",
     "analyzer" : {
        "tokenizer":{"class":"solr.StandardTokenizerFactory"},
        "filters":[
          {
            "class":"solr.StopFilterFactory",
            "ignoreCase":"true",
            "words":"stopwords.txt"
          },
          {
            "class":"solr.StandardFilterFactory"
          },
          {
            "class":"solr.LowerCaseFilterFactory"
          },
          {
            "class":"solr.RemoveDuplicatesTokenFilterFactory"
          }
      ]
    }
  }
}' $SOLR_CORE_URL/schema

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
    "stored":true,
    "indexed":false
  }
}' $SOLR_CORE_URL/schema

curl -X POST -H 'Content-type:application/json' --data-binary '{
  "add-field":{
    "name":"text",
    "type":"text_general",
    "multiValued":true,
    "stored":false,
    "indexed":true
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

curl -X POST -H 'Content-type:application/json' --data-binary '{
  "add-field":{
    "name":"uniform_related_works_display",
    "type":"string",
    "multiValued":true,
    "stored":true,
    "indexed":false,
    "docValues":false
  }
}' $SOLR_CORE_URL/schema

curl -X POST -H 'Content-type:application/json' --data-binary '{
  "add-field":{
    "name":"toc_display",
    "type":"string",
    "multiValued":true,
    "stored":true,
    "indexed":false,
    "docValues":false
  }
}' $SOLR_CORE_URL/schema

curl -X POST -H 'Content-type:application/json' --data-binary '{
  "add-field":{
    "name":"toc_970_display",
    "type":"string",
    "multiValued":true,
    "stored":true,
    "indexed":false,
    "docValues":false
  }
}' $SOLR_CORE_URL/schema

curl -X POST -H 'Content-type:application/json' --data-binary '{
  "add-field":{
    "name":"title_display",
    "type":"string",
    "multiValued":false,
    "stored":true,
    "indexed":false
  }
}' $SOLR_CORE_URL/schema

curl -X POST -H 'Content-type:application/json' --data-binary '{
  "add-field":{
    "name":"title_primary_search",
    "type":"text_general",
    "multiValued":false,
    "stored":true,
    "indexed":true
  }
}' $SOLR_CORE_URL/schema

curl -X POST -H 'Content-type:application/json' --data-binary '{
  "add-field":{
    "name":"title_vern_display",
    "type":"string",
    "multiValued":false,
    "stored":true,
    "indexed":false
  }
}' $SOLR_CORE_URL/schema

curl -X POST -H 'Content-type:application/json' --data-binary '{
  "add-field":{
    "name":"subtitle_display",
    "type":"string",
    "multiValued":false,
    "stored":true,
    "indexed":false
  }
}' $SOLR_CORE_URL/schema

curl -X POST -H 'Content-type:application/json' --data-binary '{
  "add-field":{
    "name":"subtitle_vern_display",
    "type":"string",
    "multiValued":false,
    "stored":true,
    "indexed":false
  }
}' $SOLR_CORE_URL/schema

curl -X POST -H 'Content-type:application/json' --data-binary '{
  "add-field":{
    "name":"author_display",
    "type":"string",
    "multiValued":false,
    "stored":true,
    "indexed":false
  }
}' $SOLR_CORE_URL/schema

curl -X POST -H 'Content-type:application/json' --data-binary '{
  "add-field":{
    "name":"author_vern_display",
    "type":"string",
    "multiValued":false,
    "stored":true,
    "indexed":false
  }
}' $SOLR_CORE_URL/schema

# should this be strings?
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
    "name":"language_facet",
    "type":"strings",
    "stored":true,
    "indexed":true
  }
}' $SOLR_CORE_URL/schema

curl -X POST -H 'Content-type:application/json' --data-binary '{
  "add-field":{
    "name":"subject_topic_facet",
    "type":"strings",
    "stored":true,
    "indexed":true
  }
}' $SOLR_CORE_URL/schema

curl -X POST -H 'Content-type:application/json' --data-binary '{
  "add-field":{
    "name":"subject_era_facet",
    "type":"strings",
    "stored":true,
    "indexed":true
  }
}' $SOLR_CORE_URL/schema

curl -X POST -H 'Content-type:application/json' --data-binary '{
  "add-field":{
    "name":"subject_geo_facet",
    "type":"strings",
    "stored":true,
    "indexed":true
  }
}' $SOLR_CORE_URL/schema

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
    "name":"format",
    "type":"string",
    "stored":true,
    "indexed":true
  }
}' $SOLR_CORE_URL/schema

curl -X POST -H 'Content-type:application/json' --data-binary '{
  "add-field":{
    "name":"subject_t",
    "type":"text_general",
    "multiValued":true,
    "stored":true,
    "indexed":true
  }
}' $SOLR_CORE_URL/schema

curl -X POST -H 'Content-type:application/json' --data-binary '{
  "add-field":{
    "name":"author_addl_t",
    "type":"text_general",
    "multiValued":true,
    "stored":true,
    "indexed":true
  }
}' $SOLR_CORE_URL/schema

curl -X POST -H 'Content-type:application/json' --data-binary '{
  "add-field":{
    "name":"title_series_t",
    "type":"text_general",
    "multiValued":true,
    "stored":true,
    "indexed":true
  }
}' $SOLR_CORE_URL/schema

curl -X POST -H 'Content-type:application/json' --data-binary '{
  "add-field":{
    "name":"title_t",
    "type":"text_general",
    "multiValued":true,
    "stored":true,
    "indexed":true
  }
}' $SOLR_CORE_URL/schema

curl -X POST -H 'Content-type:application/json' --data-binary '{
  "add-field":{
    "name":"author_t",
    "type":"text_general",
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

curl -X POST -H 'Content-type:application/json' --data-binary '{
  "add-field":{
    "name":"issn_t",
    "type":"text_general",
    "multiValued":true,
    "stored":true,
    "indexed":true
  }
}' $SOLR_CORE_URL/schema


# ====================
# Dynamic Fields
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
    "name":"*_sort",
    "type":"alphaOnlySort",
    "multiValued":false,
    "stored":false,
    "indexed": true
  }
}' $SOLR_CORE_URL/schema

curl -X POST -H 'Content-type:application/json' --data-binary '{
  "add-dynamic-field":{
    "name":"*_unstem_search",
    "type":"text_general",
    "multiValued":true,
    "stored":false,
    "indexed": true
  }
}' $SOLR_CORE_URL/schema

curl -X POST -H 'Content-type:application/json' --data-binary '{
  "add-dynamic-field":{
    "name":"*spell",
    "type":"text_general",
    "multiValued":true,
    "stored":false,
    "indexed": true
  }
}' $SOLR_CORE_URL/schema

curl -X POST -H 'Content-type:application/json' --data-binary '{
  "add-field":{
    "name":"author_cjk",
    "type":"text_cjk",
    "multiValued":true,
    "stored":true,
    "indexed":true
  }
}' $SOLR_CORE_URL/schema

# ====================
# Copy Fields
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

echo "Done."
