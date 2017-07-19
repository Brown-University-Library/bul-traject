# bul-traject
This project transforms MARC records into Solr documents using the [Traject](https://github.com/traject-project/traject) tools developed by [Bill Dueber](https://github.com/billdueber/) and [Jonathan Rochkind](https://github.com/jrochkind).

[![Build Status](https://secure.travis-ci.org/Brown-University-Library/bul-traject.png?branch=master)](https://travis-ci.org/Brown-University-Library/bul-traject)

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
