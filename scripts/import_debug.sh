MARC_FILE=~/data/combined/combined_08.mrc
export CJK=true

bundle exec traject --debug-mode -w JsonWriter -c config.rb $MARC_FILE > combined_xx.json 2>&1

