# Before October/2019

## Field definitions

The definition of the **text_en** field type. Notice that it uses English
specific filters (EnglishPossessiveFilterFactory and PorterStemFilterFactory)
and that the settings for indexing (indexAnalyzer) are different from the
settings for querying (queryAnalyzer).

```
$ curl localhost:8983/solr/cjktest/schema/fieldtypes/text_en
{
  "responseHeader":{
    "status":0,
    "QTime":1},
  "fieldType":{
    "name":"text_en",
    "class":"solr.TextField",
    "positionIncrementGap":"100",
    "indexAnalyzer":{
      "tokenizer":{
        "class":"solr.StandardTokenizerFactory"},
      "filters":[{
          "class":"solr.StopFilterFactory",
          "words":"lang/stopwords_en.txt",
          "ignoreCase":"true"},
        {
          "class":"solr.LowerCaseFilterFactory"},
        {
          "class":"solr.EnglishPossessiveFilterFactory"},
        {
          "class":"solr.KeywordMarkerFilterFactory",
          "protected":"protwords.txt"},
        {
          "class":"solr.PorterStemFilterFactory"}]
        },
    "queryAnalyzer":{
      "tokenizer":{
        "class":"solr.StandardTokenizerFactory"},
      "filters":[{
          "class":"solr.SynonymGraphFilterFactory",
          "expand":"true",
          "ignoreCase":"true",
          "synonyms":"synonyms.txt"},
        {
          "class":"solr.StopFilterFactory",
          "words":"lang/stopwords_en.txt",
          "ignoreCase":"true"},
        {
          "class":"solr.LowerCaseFilterFactory"},
        {
          "class":"solr.EnglishPossessiveFilterFactory"},
        {
          "class":"solr.KeywordMarkerFilterFactory",
          "protected":"protwords.txt"},
        {
          "class":"solr.PorterStemFilterFactory"
        }
      ]
    }
  }
}
```

The definition of the **text_cjk** field type uses CJK specific filters
(CJKWidthFilterFactory and CJKBigramFilterFactory)

```
$ curl localhost:8983/solr/cjktest/schema/fieldtypes/text_cjk
{
  "responseHeader":{
    "status":0,
    "QTime":0},
  "fieldType":{
    "name":"text_cjk",
    "class":"solr.TextField",
    "positionIncrementGap":"100",
    "analyzer":{
      "tokenizer":{
        "class":"solr.StandardTokenizerFactory"},
      "filters":[{
          "class":"solr.CJKWidthFilterFactory"},
        {
          "class":"solr.LowerCaseFilterFactory"},
        {
          "class":"solr.CJKBigramFilterFactory"
        }
      ]
    }
  }
}
```


## Testing with our data

Classic Josiah BIB records for author "张爱玲" (Zhang, Ailing)
* b3254870
* b2443451
* b3254953
* b7084450
* b3432221
* b6524958
* b4106491

Some incorrect matches from new Josiah for the same search:
* b7835116 (author 张爱军)
* b3666424 (author 张爱国)
* b3666425 (author 张爱国)
* b7996223 (author 王爱玲, 1971-)


CJK readings
* CJK with Solr for Libraries, part 8  http://discovery-grindstone.blogspot.com/2014/01/cjk-with-solr-for-libraries-part-8.html

* Multilingual Issues Part 1: Word Segmentation https://www.hathitrust.org/blogs/large-scale-search/multilingual-issues-part-1-word-segmentation

* Some info on bigrams https://ocelot.ca/blog/blog/2014/01/01/mroonga-and-me-and-mariadb/

## More Solr stuff

Read the (Language Analysis)[https://lucene.apache.org/solr/guide/7_0/language-analysis.html#language-analysis] section in the Solr guide.

Take a look at the ICU Tokenizer which "processes multilingual text and tokenizes it appropriately based on its script attribute." https://lucene.apache.org/solr/guide/7_0/tokenizers.html#icu-tokenizer


## Open questions

* What happens with text in the middle when using the CJK Filters? I think this is handled OK by the CJKFilter. See the issue with "何永红" below, it looks like it is not doing a dumb "starts with" kind of match.

* A search for "何永红" is parsed as "何永" or "永红". Why?
```
  <str name="querystring">author_cjk:何永红</str>
  <str name="parsedquery">+(author_cjk:何永 author_cjk:永红)</str>
```

Documents found: b4034277 and b4065326

* Interesting query: "遠藤元男" with and without quotes.



## Solr 7 changes

https://lucene.apache.org/solr/guide/7_0/major-changes-in-solr-7.html
http://pychuang-blog.logdown.com/posts/230677-upgrade-solr-for-citeseerx
https://lucene.apache.org/solr/guide/6_6/requestdispatcher-in-solrconfig.html


Information of `handleSelect`: http://pychuang-blog.logdown.com/posts/230677-upgrade-solr-for-citeseerx

qt parameter now behaves different and BL relies on it. Must use `<requestDispatcher handleSelect="true">`
and make sure there is no `/select` request handler defined.

`solrQueryParser defaultOperator` used to be defined in schema.xml but is not supported anymore, we now need to define it as `q.op` in solrconfig.xml. See [Changed default operator in Solr 5](https://www.drupal.org/project/1600962/issues/2486533) and also https://issues.apache.org/jira/browse/SOLR-2724

Links from Ben Cail:
* Here's a commit for our solr config for SOW (split-on-whitespace) setting ("SOW is a parameter that caused issues for us, until I changed it back to
the old default."): https://bitbucket.org/bul/bdr_solr_conf/commits/40fe0d387b3fda461208bbd04a6d5a81da199605
* See also: http://yonik.com/solr-7/
* See also: http://lucene.apache.org/solr/7_0_0/changes/Changes.html#v7.0.0.upgrading_from_solr_6.x



## LocalParams
Local Parameters have been drastically changed in Solr 7, they are [not supported by default](https://lucene.apache.org/solr/guide/7_5/solr-upgrade-notes.html) unless you are using the Lucene parser as the starting point.

In Solr 4 (using `defType=dismax`) the search `q={!dismax%20qf=title_t}gothic&rows=0&debug=true` searches for the word "gothic" in `title_f` but also on all the fields indicated in `qf` value in solrconfig.xml (title_unstem_search, title_series_t, author_addl_t, ...)

In Solr 7 (using `defType=dismax`) however, the same search will issue a search for "dismax", "qf", "title_t", and "gothic" as it did not parse the text inside the `{! ... }`

I understand that you can get back the old behavior by switching to LuceneMatchVersion 7.1.0. That change alone does not work for me.

```
  <luceneMatchVersion>7.1.0</luceneMatchVersion>
```

See also https://blog.andornot.com/blog/restore-local-params-in-solr-7.5/ in which he recommends adding a `uf` parameter. Did not work for me.

```
    <str name="uf">* _query_</str>
```


### Local Params - test using lucene as default defType
Updated `solrconfig.xml` as follows:

```
    <str name="defType">lucene</str>
    <str name="qf">...
    <str name="pf">...
```

A search for `rows=0&debug=true&q={!dismax}gothic` works as expected.

Pros:
* Uses default `qf` and `pf` from solrconfig.xml

Cons:
* Must specify `dismax` via LocalParams in each query.

Notice that although I can pass a new `qf` via LocalParams, and it will be honored, it will be used **in addition** to the `qf` value in `solrconfig.xml`. It seems that this was the behavior in Solr 4 as well.

Using `q={!qf=$title_qf}gothic` gives also a different number of results (~1300) than using `q=gothic` (~5000).

