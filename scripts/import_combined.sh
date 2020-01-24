MARC_PATH=~/data/combined/combined_*.mrc
SOLR_URL=http://localhost:8983/solr/josiah7
export CJK=true

echo "Import started at $(date)" >combined.txt
echo "  $MARC_PATH" >>combined.txt
echo "  $SOLR_URL" >>combined.txt

for FILE in `ls -m1 $MARC_PATH`
do
  echo "Processing $FILE" >>combined.txt
  if [ $FILE = "/Users/hectorcorrea/data/combined/skip.mrc" ]
  then
    echo "skip $FILE"
    continue
  fi

  bundle exec traject -c config.rb -u $SOLR_URL $FILE >>combined.txt 2>&1
  curl $SOLR_URL/update?commit=true >>combined.txt
done

echo "Done importing at $(date)" >>combined.txt

grep -v "/Users/hectorcorrea/.gem" combined.txt > combined_small.txt