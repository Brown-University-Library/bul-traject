# Finds a MARC record using marcli
# (https://github.com/hectorcorrea/marcli)
MARC_PATH=~/data/combined/combined_*.mrc
for FILE in `ls -m1 $MARC_PATH`
do
    echo "Processing $FILE"
    ~/src/marcli/cmd/marcli/marcli -file $FILE | grep "b2445229"
done
