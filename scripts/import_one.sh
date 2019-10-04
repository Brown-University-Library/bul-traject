MARC_FILE=~/data/combined_09.mrc
SOLR_URL=http://localhost:8983/solr/cjkdemo
#SOLR_URL=http://localhost:8081/solr/blacklight-core

echo "Importing"
echo "  $MARC_FILE"
echo "  $SOLR_URL"
# >out.txt 2>&1
bundle exec traject -c config.rb -u $SOLR_URL $MARC_FILE

curl $SOLR_URL/update?commit=true
echo "Done."
