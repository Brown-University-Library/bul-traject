#
#Brown MARC to Solr indexing
#Uses traject: https://github.com/traject-project/traject
#
# This is a copy of the original config.rb but updated to
# _only_ output records that were suppressed. This is with
# the intention of deleting these records from Solr (rather
# than skipping them from processing as config.rb does)

#Check if we are using jruby and store.
is_jruby = RUBY_ENGINE == 'jruby'
if is_jruby
  require 'traject/marc4j_reader'
end

#Translation maps.
# './lib/translation_maps/'
$:.unshift  "#{File.dirname(__FILE__)}/lib"

require 'traject/macros/marc21_semantics'
extend  Traject::Macros::Marc21Semantics

require 'traject/macros/marc_format_classifier'
extend Traject::Macros::MarcFormats

#local macros
require 'bul_macros'
extend BulMacros

#local utils
require 'bul_utils'
require 'bul_format'

# Setup
settings do
  store "log.batch_progress", 10_000
  provide "solr.url", ENV['SOLR_URL']
  #Use Marc4JReader and solrj writer when available.
  if is_jruby
    provide "reader_class_name", "Traject::Marc4JReader"
    provide "marc4j_reader.source_encoding", "UTF-8"
    provide "solrj_writer.commit_on_close", "true"
    # Use more threads on local box.
    if ENV['TRAJECT_ENV'] == "devbox"
      provide 'processing_thread_pool', 8
    else
      provide 'processing_thread_pool', 3
    end
  end
end

logger.info RUBY_DESCRIPTION

each_record do |rec, context|
  if suppressed(rec) == true
  else
    context.skip!("Skipping record")
  end
end

#Brown record id
to_field "id", record_id
