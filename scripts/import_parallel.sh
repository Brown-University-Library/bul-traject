#!/bin/sh
#
# Imports MARC files into Solr via Traject.
# It runs multiple imports at once. The number of concurrent
# processes is controlled via the CONCURRENT variable.
# See https://www.cyberciti.biz/faq/how-to-run-command-or-code-in-parallel-in-bash-shell-under-linux-or-unix/
#

process_marc_file(){
    # Process with Traject the indicated file
    echo "Processing $1" >>$LOG_FILE
    bundle exec traject -c config.rb -u $SOLR_URL $FILE >>$TRAJECT_LOG_FILE 2>&1
    echo "Done with $1" >>$LOG_FILE
}

export MARC_PATH=~/data/combined/combined_*.mrc
export SOLR_URL=http://localhost:8983/solr/josiah7
export CJK=true
export LOG_FILE=/Users/hectorcorrea/dev/bul-traject/scripts/parallel.log
export TRAJECT_LOG_FILE=/Users/hectorcorrea/dev/bul-traject/scripts/traject.log
export TRAJECT_SMALL_LOG_FILE=/Users/hectorcorrea/dev/bul-traject/scripts/traject_small.log
export CONCURRENT=2
export COUNTER=0

# Truncate the previous log files
echo "" >$TRAJECT_LOG_FILE
echo "" >$LOG_FILE

# Truncate the previous log
echo "Import started at $(date)" >>$LOG_FILE
echo "  $MARC_PATH" >>$LOG_FILE
echo "  $SOLR_URL" >>$LOG_FILE

for FILE in `ls -m1 $MARC_PATH`
do
    # Queue the next file...
    COUNTER=$((COUNTER+1))
    echo "Queueing $FILE" >>$LOG_FILE
    process_marc_file $FILE &

    if [ "$COUNTER" -eq "$CONCURRENT" ]
    then
        # ...wait and commit
        echo "Waiting at $(date)..." >>$LOG_FILE
        wait
        echo "Committing at $(date)..." >>$LOG_FILE
        curl $SOLR_URL/update?commit=true >>$LOG_FILE
        COUNTER=0
    fi
done

if [ "$COUNTER" -ne "0" ]
then
    # ...wait and commit last batch (if any)
    echo "Waiting last at $(date)..." >>$LOG_FILE
    wait
    echo "Committing last at $(date)..." >>$LOG_FILE
    curl $SOLR_URL/update?commit=true >>$LOG_FILE
fi

echo "Done importing at $(date)" >>$LOG_FILE

# grep -v "/.gem/ruby/" $TRAJECT_LOG_FILE > $TRAJECT_SMALL_LOG_FILE