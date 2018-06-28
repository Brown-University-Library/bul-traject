# bul-traject
This project transforms MARC records into Solr documents using the
[Traject](https://github.com/traject-project/traject) tools developed by
[Bill Dueber](https://github.com/billdueber/) and
[Jonathan Rochkind](https://github.com/jrochkind).

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
We use a separate process to handle deleted/suppressed records.
See [bibService project] for more information on this.


## Scripts
Folder `./scripts` contains a few sample Bash scripts used to run Traject to
import a group of files, individual files, or for debug purposes.
