# Notes on Solr and CJK support

Start by reading (Indexing Chinese in Solr)[https://opensourceconnections.com/blog/2011/12/23/indexing-chinese-in-solr/] by Jason Hull (2011).


## Create a Solr core for demo purposes
```
# solr delete -c cjktest
$ solr create -c cjktest
$ post -c cjktest data.json
```


## Queries using the English fields returns too many results
```
# Search for 胡志明 (Hồ Chí Minh)
$ ue "localhost:8983/solr/cjktest/select?q=title_txt_en:胡志明" | xargs curl

# Search for 胡 (recklessly)
$ ue "localhost:8983/solr/cjktest/select?q=title_txt_en:胡" | xargs curl

# Search for 胡说 (nonsense)
$ ue "localhost:8983/solr/cjktest/select?q=title_txt_en:胡说" | xargs curl
```

If we inspect the debugQuery values (debugQuery=true) for the nonsense (胡说)
example we'll see that the query was parsed as two pieces "胡" and "说" when we
used the English field:

```
"parsedquery":"title_txt_en:胡 title_txt_en:说",
```

## Queries using the CJK fields return the correct results
```
# Search for 胡志明 (Hồ Chí Minh)
$ ue "localhost:8983/solr/cjktest/select?q=title_txt_cjk:胡志明" | xargs curl

# Search for 胡 (recklessly)
$ ue "localhost:8983/solr/cjktest/select?q=title_txt_cjk:胡" | xargs curl

# Search for 胡说 (nonsense)
$ ue "localhost:8983/solr/cjktest/select?q=title_txt_cjk:胡说" | xargs curl
```

but it is correctly parsed as a single token when we used the CJK field:

```
"parsedquery":"title_txt_cjk:胡说",
```


## A query in English
This query shows how Solr picks up documents with the word "hello" regardless
of where it is found in the title.

```
$ ue "localhost:8983/solr/cjktest/select?q=title_txt_en:hello" | xargs curl
```


