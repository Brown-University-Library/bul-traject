require 'traject'
require 'socket'


settings do

  # This is just regular ruby, so don't be afraid to have conditionals!
  # Switch on hostname, for test and production server differences
  if Socket.gethostname =~ /devhost/
    provide "solr.url", "http://my.dev.machine:9033/catalog"
  else
    provide "solr.url", "http://my.production.machine:9033/catalog"
  end
  
  provide "solrj_writer.parser_class_name", "BinaryResponseParser" # for Solr 4.x
  # provide "solrj_writer.parser_class_name", "XMLResponseParser" # For solr 1.x or 3.x
  
  provide "solrj_writer.commit_on_close", "true"
  provide "solrj_writer.thread_pool", 1
  provide "solrj_writer.batch_size", 150
  provide "writer_class_name", "Traject::SolrJWriter"
  
  provide 'processing_thread_pool', 3
end
