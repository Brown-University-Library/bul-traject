# bul-traject
This project transforms MARC records into Solr documents using the [Traject](https://github.com/traject-project/traject) tools developed by [Bill Dueber](https://github.com/billdueber/) and [Jonathan Rochkind](https://github.com/jrochkind).

Run as:
```
traject -c config.rb -u http://localhost:8081/solr/blacklight-core /full/path/to/marcfile.mrc

curl http://localhost:8081/solr/blacklight-core/update?commit=true
```

For testing purposes you can run `traject` with the `--debug-mode` flag to
display the output to the console (and not push the data to Solr).

```
traject --debug-mode -c config.rb /full/path/to/marcfile.mrc
```


## Handling suppressed records
In order to delete documents from Solr for records that have been deleted in
Millennium we use a two step process. This is a bit of a kludge but it works OK
for now.

First, run Traject with a special configuration file to output to a JSON
file the IDs (BIB #) of any records that have been marked as suppressed.

```
bundle exect traject -w JsonWriter -c config_delete.rb /full/path/to/update_rec_N_file.mrc > to_delete.json
```

Then process this JSON file to actually delete the records from Solr.

```
source .env
ruby process_delete.rb to_delete.json
```

(.env defines SOLR_URL)

Notice that in this case we run Traject against our daily *update* MARC files,
not against our full MARC files. The daily update files only include records
that changed in the last day or two. (TODO: how long does it take to run it
against the full files?)
