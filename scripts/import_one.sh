SOLR_URL=http://localhost:8081/solr/blacklight-core
MARC_FILE=./path/to/marc/file.mrc

echo "Importing"
echo "  $MARC_FILE"
echo "  $SOLR_URL"
traject -c config.rb -u $SOLR_URL $MARC_FILE

curl $SOLR_URL/update?commit=true
echo "Done."
