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



## ERRORS IN JOSIAH
We are getting the error on Blacklight because the `stats` data for `pub_date`
is coming incorrectly. I am not sure if Solr 7 is giving the information different
from Solr 4 or if there is a setting `solrconfig.xml` that I need to tweak to
get the same results as I am getting in production.

I am currently looking into adding a new request handler in `solrconfig.xml`
that will mimic the settings that we use in Solr 4.


## Solr 7 changes

https://lucene.apache.org/solr/guide/7_0/major-changes-in-solr-7.html
http://pychuang-blog.logdown.com/posts/230677-upgrade-solr-for-citeseerx
https://lucene.apache.org/solr/guide/6_6/requestdispatcher-in-solrconfig.html

qt parameter now behaves different and BL relies on it. Must use `<requestDispatcher handleSelect="true">`
and make sure there is no `/select` request handler defined.

Links from Ben Cail:
* Here's a commit for our solr config for SOW (split-on-whitespace) setting ("SOW is a parameter that caused issues for us, until I changed it back to
the old default."): https://bitbucket.org/bul/bdr_solr_conf/commits/40fe0d387b3fda461208bbd04a6d5a81da199605
* See also: http://yonik.com/solr-7/
* See also: http://lucene.apache.org/solr/7_0_0/changes/Changes.html#v7.0.0.upgrading_from_solr_6.x


