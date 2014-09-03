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

#Local format code
require 'lib/brown_format'


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

# Get a marc4j record for conversion to XML, because the
# stock ruby-marc XML serialization code is dog-slow
#
# First, define a converter *outside* of the block. This way I only create the
# object once, instead of once for every record!

marc_converter = MARC::MARC4J.new(:jardir => settings['marc4j_reader.jar_dir'])

# Go ahead and create a marc4j record object and hang onto it on the clipboard,
# since I know I'm gonna need it later.
each_record do |rec, context|
  context.clipboard[:marc4j] = {}
  context.clipboard[:marc4j][:marc4j_record] = marc_converter.rubymarc_to_marc4j(rec)
  if suppressed(rec) == true
    context.skip!("Skipping suppressed record")
  end
  #We will use this twice so hang on to it.
  context.clipboard[:is_online] = online(rec)
end



################################
###### CORE FIELDS #############
################################

#Brown record id
to_field "id" do |record, accumulator |
  accumulator << record_id(record)
end

#Brown last updated date
to_field "updated_dt" do |record, accumulator |
 accumulator << updated_date(record)
end

#Online boolean
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

#Building facet
#Unique list of 945s sf l processed through the translation map.
to_field "building_facet", extract_marc('945l') do |record, acc|
  acc.map!{|code| TranslationMap.new("buildings")[code.downcase[0]]}.uniq!
end

to_field 'format' do |record, accumulator|
  #tmap = Traject::TranslationMap.new('umich/format')
  tmap = Traject::TranslationMap.new('format')
  begin
    bru = BrownFormat.new(record)
    tcode = bru.primary
    accumulator << tmap[tcode]
  rescue NoMethodError
    puts "Error at " + record_id(record)
  end
end

to_field 'language_facet', marc_languages("008[35-37]:041a:041d:041e:041j")

to_field 'isbn_t', extract_marc('020a:020z')
to_field 'issn_t', extract_marc("022a:022l:022y:773x:774x:776x", :separator => nil)
to_field 'oclc_t', oclcnum('035a:035z')

# Title fields
to_field 'title_t', extract_marc('245abc', :first=>true, :trim_punctuation => true)
#title_display
#Here we will vary a bit from Blacklight and join other subfields.
to_field 'title_display', extract_marc('245abk', :first=>true, :trim_punctuation => true)
to_field 'title_vern_display', extract_marc('245abk', :alternate_script=>:only, :trim_punctuation => true, :first=>true)

#We will skip these for now
#subtitle
#subtitle_t = custom, getLinkedFieldCombined(245b)
#subtitle_display = custom, removeTrailingPunct(245b)
#subtitle_vern_display = custom, getLinkedField(245b)

#Additional title
#Figure out later.
#title_addl_t = custom, getLinkedFieldCombined(245abnps:130[a-z]:240[a-gk-s]:210ab:222ab:242abnp:243[a-gk-s]:246[a-gnp]:247[a-gnp])
#title_added_entry_t

to_field "title_series_t", extract_marc("440ap:800abcdfpqt:830ap")
to_field "title_sort", marc_sortable_title

# Author fields
to_field "author_display", extract_marc("100abcdq:110abcd:111abcd", :first=>true, :trim_punctuation => true)
to_field "author_vern_display", extract_marc('100abcdq:110abcd:111abcd', :alternate_script=>:only, :trim_punctuation => true, :first=>true)
to_field "author_addl_display", extract_marc('110ab:111ab:700abcd:710ab:711ab', :trim_punctuation => true)

to_field "author_t", extract_marc('100abcd:110abcd:111abc')
to_field 'author_addl_t', extract_marc("700abcd:710abcd:711abc")


to_field "author_sort", extract_marc("100abcd:110abcd:111abc:110ab:700abcd:710ab:711ab", :first=>true)

#Subject fields
#subject_t = custom, getLinkedFieldCombined(600[a-u]:610[a-u]:611[a-u]:630[a-t]:650[a-e]:651ae:653aa:654[a-e]:655[a-c])
#subject_addl_t = custom, getLinkedFieldCombined(600[v-z]:610[v-z]:611[v-z]:630[v-z]:650[v-z]:651[v-z]:654[v-z]:655[v-z])
#subject_topic_facet = custom, removeTrailingPunct(600abcdq:610ab:611ab:630aa:650aa:653aa:654ab:655ab)
#subject_era_facet = custom, removeTrailingPunct(650y:651y:654y:655y)
#subject_geo_facet = custom, removeTrailingPunct(651a:650z)

#https://github.com/billdueber/ht_traject/blob/master/indexers/common.rb

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


#to_field "subject_topic_facet", extract_marc("600abcdq:610ab:611ab:630aa:650aa:653aa:654ab:655ab", :trim_punctuation => true)
#to_field 'subject_era_facet', marc_era_facet
#to_field "subject_geo_facet", marc_geo_facet

to_field "topic_facet", extract_marc("650a:690a", :trim_punctuation => true)

# Publication fields
to_field "published_display", extract_marc("260a", :trim_punctuation=>true)
to_field "published_vern_display",  extract_marc("260a", :alternate_script => :only)

#Display physical information.
to_field 'physical_display', extract_marc('300abcefg:530abcd')

to_field "pub_date", marc_publication_date

to_field "abstract_display", extract_marc("520a", :first=>true)

#Not sure this is necessary since we will be pulling call numbers
#from availability service.
#to_field "lc_callnum_display", extract_marc("050ab", :first=>true)


# URL Fields - these will have to be custom, most likely.
to_field "url_fulltext_display", extract_marc("856u")
to_field "url_suppl_display", extract_marc("856z")

# Get the values for all the fields between 100 and 999
to_field "text", extract_all_marc_values(:from=>'100', :to=>'999')

# to_field 'marc_display' do |r, acc, context|
#   xmlos = java.io.ByteArrayOutputStream.new
#   writer = org.marc4j.MarcXmlWriter.new(xmlos)
#   writer.setUnicodeNormalization(true)
#   writer.write(context.clipboard[:marc4j][:marc4j_record])
#   writer.writeEndDocument();
#   acc << xmlos.toString
# end