# Brown MARC record indexer

Based off (https://github.com/traject-project/traject_sample)

Run as:
`time traject -c bul_index.rb -u http://localhost:8983/solr/blacklight-core /full/path/to/marcfile.mrc`

or for a directory of records:
`cat /dock/josiahdata/updates/*mrc | time traject -c bul_index.rb -u http://localhost:8983/solr/blacklight-core --stdin -s solrj_writer.commit_on_close=true`


