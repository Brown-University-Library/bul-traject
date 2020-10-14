MARC_FILE=~/data/combined/combined_02.mrc
SOLR_URL=http://localhost:8983/solr/josiah7

echo "Importing"
echo "  $MARC_FILE"
echo "  $SOLR_URL"
bundle exec traject -c config.rb -u $SOLR_URL $MARC_FILE >out.txt 2>&1

curl $SOLR_URL/update?commit=true
echo "Done."
