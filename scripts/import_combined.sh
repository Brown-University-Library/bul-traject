MARC_PATH=~/data/combined/combined_*.mrc
SOLR_URL=http://localhost:8983/solr/cjkdemo

echo "Import started at $(date)" >combined.txt
echo "  $MARC_PATH" >>combined.txt
echo "  $SOLR_URL" >>combined.txt

for FILE in `ls -m1 $MARC_PATH`
do
  echo "Processing $FILE" >>combined.txt
  bundle exec traject -c config.rb -u $SOLR_URL $FILE >>combined.txt 2>&1
  curl $SOLR_URL/update?commit=true >>combined.txt
done

echo "Done importing at $(date)" >>combined.txt

grep -v "/Users/hectorcorrea/.gem" combined.txt > combined_small.txt