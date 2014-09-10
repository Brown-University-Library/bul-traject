#
#Brown MARC to Solr indexing
#Uses tracject: https://github.com/traject-project/traject
#

# I like to keep my local files under 'lib'. Adding this will also
# allow Traject::TranslationMap to find files in
# './lib/translation_maps/'
$:.unshift  "#{File.dirname(__FILE__)}/lib"

require 'traject/macros/marc21_semantics'
extend  Traject::Macros::Marc21Semantics

require 'traject/macros/marc_format_classifier'
extend Traject::Macros::MarcFormats

require 'traject/marc4j_reader'

#Local utils gem
require 'bulmarc'

#local macros
require 'lib/brown_macros'
extend BrownMacros


# set this depending on what you want to see
# and how often.
settings do
  store "log.batch_progress", 10_000
  provide "reader_class_name", "Traject::Marc4JReader"
  provide "marc4j_reader.source_encoding", "UTF-8"
  provide "solr.url", ENV['SOLR_URL']
  provide "solrj_writer.commit_on_close", "true"
  provide 'processing_thread_pool', 3
end

logger.info RUBY_DESCRIPTION

#Handle MARC XML serialization.  See: https://github.com/traject-project/traject_sample/blob/master/index.rb#L121
#marc_converter = MARC::MARC4J.new(:jardir => settings['marc4j_reader.jar_dir'])

each_record do |rec, context|
  if suppressed(rec) == true
    rid = record_id(rec)
    context.skip!("Skipping suppressed record #{rid}")
  end
  #We will use this twice so hang on to it.
  context.clipboard[:is_online] = online(rec)
end

#Brown record id
to_field "id" do |record, accumulator |
  accumulator << record_id(record)
end

#Brown last updated date
to_field "updated_dt" do |record, accumulator |
 accumulator << updated_date(record)
end


#Identifiers
to_field 'isbn_t', extract_marc('020a:020z')
to_field 'issn_t', extract_marc("022a:022l:022y:773x:774x:776x", :separator => nil)
to_field 'oclc_t', oclcnum('035a:035z')

# Title fields
to_field 'title_t', extract_marc('245abc', :first=>true, :trim_punctuation => true)
to_field 'title_display', extract_marc('245abk', :first=>true, :trim_punctuation => true)
to_field 'title_vern_display', extract_marc('245abk', :alternate_script=>:only, :trim_punctuation => true, :first=>true)
to_field "title_series_t", extract_marc("440ap:800abcdfpqt:830ap")
to_field "title_sort", marc_sortable_title

# Author fields
to_field "author_display", extract_marc("100abcdq:110abcd:111abcd", :first=>true, :trim_punctuation => true)
to_field "author_vern_display", extract_marc('100abcdq:110abcd:111abcd', :alternate_script=>:only, :trim_punctuation => true, :first=>true)
to_field "author_addl_display", extract_marc('110ab:111ab:700abcd:710ab:711ab', :trim_punctuation => true)
to_field "author_t", extract_marc('100abcd:110abcd:111abc')
to_field 'author_addl_t', extract_marc("700abcd:710abcd:711abc")



#
# - Publication details fields
#
to_field "published_display", extract_marc("260a", :trim_punctuation=>true)
to_field "published_vern_display",  extract_marc("260a", :alternate_script => :only)
#Display physical information.
to_field 'physical_display', extract_marc('300abcefg:530abcd')
to_field "abstract_display", extract_marc("520a", :first=>true)
to_field "pub_date", marc_publication_date

#URL Fields - these will have to be custom, most likely.
to_field "url_fulltext_display", extract_marc("856u")
to_field "url_suppl_display", extract_marc("856z")

#Online true/false
to_field "online_b" do |record, accumulator, context|
  accumulator << context.clipboard[:is_online]
end

#Access facet
to_field "access_facet" do |record, accumulator, context|
  online = context.clipboard[:is_online]
  if online == true
    val = "Online"
  else
    val = "At the library"
  end
  accumulator << val
end


#
# - Facet fields
#

#Custom logic coming from bulmarc
to_field 'format' do |record, accumulator|
  tmap = Traject::TranslationMap.new('format')
  bf = BulMarc::Format.new(record)
  value = tmap[bf.code]
  accumulator << value
end

#Author - local macro
to_field "author_facet", author_facet
#Language
to_field 'language_facet', marc_languages("008[35-37]:041a:041d:041e:041j")

#Buildings - Unique list of 945s sf l processed through the translation map.
to_field "building_facet", extract_marc('945l') do |record, acc|
  acc.map!{|code| TranslationMap.new("buildings")[code.downcase[0]]}.uniq!
end
to_field "region_facet", marc_geo_facet
to_field "topic_facet", extract_marc("650a:690a", :trim_punctuation => true)



#
# - Search fields
#

#Subject search.  See: https://github.com/billdueber/ht_traject/blob/master/indexers/common.rb
to_field "subject_t", extract_marc(%w(
  600a  600abcdefghjklmnopqrstuvxyz
  610a  610abcdefghklmnoprstuvxyz
  611a  611acdefghjklnpqstuvxyz
  630a  630adefghklmnoprstvxyz
  648a  648avxyz
  650a  650abcdevxyz
  651a  651aevxyz
  653a  654abevyz
  654a  655abvxyz
  655a  656akvxyz
  656a  657avxyz
  657a  658ab
  658a  662abcdefgh
  690a   690abcdevxyz
  ), :trim_punctuation=>true)

#Text - for search
# Get the values for all the fields between 100 and 999
to_field "text", extract_all_marc_values(:from=>'100', :to=>'999')

#Not using marc_display yet.
# to_field 'marc_display' do |r, acc, context|
#   xmlos = java.io.ByteArrayOutputStream.new
#   writer = org.marc4j.MarcXmlWriter.new(xmlos)
#   writer.setUnicodeNormalization(true)
#   writer.write(context.clipboard[:marc4j][:marc4j_record])
#   writer.writeEndDocument();
#   acc << xmlos.toString
# end