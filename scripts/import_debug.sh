MARC_FILE=~/data/combined/combined_33.mrc
export CJK=true

bundle exec traject --debug-mode -w JsonWriter -c config.rb $MARC_FILE

# > combined_33.json 2>&1

