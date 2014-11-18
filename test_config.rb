#
# Bare config for testing new mappings.
#
require 'traject'
require 'traject/debug_writer'

#translation maps
$:.unshift  "#{File.dirname(__FILE__)}/lib"

require 'traject/macros/marc21_semantics'
require 'traject/macros/marc21'
require 'traject/marc_extractor'

require 'bul_macros'
require 'bul_utils'

extend  Traject::Macros::Marc21Semantics
extend BulMacros


# The add the appropriate settings
settings do
  #provide "reader_class_name", "Traject::Marc4JReader"
  provide "solr.url", ENV['SOLR_URL']
  #provide "reader_class_name", "Traject::MarcReader"
  # Right now, logging is going to $stderr. Uncomment
  # this line to send it to a file
  # provide 'log.file', 'traject.log'
end
# Log what version of jruby/java we're using

logger.info RUBY_DESCRIPTION

each_record do |rec, context|
  puts rec
  if suppressed(rec) == true
    context.skip!("Skipping suppressed record")
  end
end

to_field "id", record_id

#Brown last updated date
# to_field "updated_dt" do |record, accumulator |
#  accumulator << updated_date(record)
# end

to_field "title", extract_marc('245a')
#to_field "brown_author_facet", author_facet
#to_field "author", extract_marc("100abcdq:110abcd:111abcd", :first=>true, :trim_punctuation => true)
#to_field "imprint_display", extract_marc("260abcdefg:264abc", :first=>true)

# Title fields
to_field 'title_t', extract_marc(%w(
  245abfgknp
  100tflnp
  110tflnp
  111tfklpsv
  130adfklmnoprst
  210ab
  222ab
  240adfklmnoprs
  242abnp
  246abnp
  247abnp
  505t
  700tflnp
  710tflnp
  711tfklpsv
  730adfklmnoprstv
  740ap
  ),
  :first=>true,
  :trim_punctuation => true
)



#format_map = Traject::TranslationMap.new('format')
# Various librarians like to have the actual 008 language code around
# to_field 'format' do |record, accumulator|
#   # content_type_spec = Traject::MarcExtractor.cached('337a')
#   # value = content_type_spec.extract(record).first
#   # unless value.nil?
#   #   accumulator << value
#   #   next
#   # end
#   bf = BulMarc::Format.new(record).code
#   value = format_map[bf]
#   accumulator << value
# end

# to_field "building_facet", extract_marc('945l') do |record, acc|
#   acc.map!{|code| TranslationMap.new("buildings")[code.downcase[0]]}.uniq!
# end

#Brown buildings
# to_field "building_facet" do |record, accumulator |
#  accumulator << TranslationMap.new("buildings")bul_buildings(record)
# end

#to_field "zed", extract_marc('bul_format')

#to_field 'oclc_t', oclcnum('035a:035z')
#to_field 'series', extract_marc('440ap:800abcdfpqt:830ap')

#to_field 'lcsh', marc_lcsh_formatted()
#to_field 'physical_display', extract_marc('300abcefg:530abcd')

# to_field 'bru_um_tracject_format' do |record, accumulator|
#   #tmap = Traject::TranslationMap.new('umich/format')
#   tmap = Traject::TranslationMap.new('format')
#   begin
#     bru = BrownFormat.new(record)
#     tcode = bru.primary
#     accumulator << tmap[tcode]
#   rescue NoMethodError
#     puts "Error at " + record_id(record)
#   end
# end

# to_field 'bulmarc_format' do |record, accumulator|
#   tmap = Traject::TranslationMap.new('format')
#   bf = BulMarc::Format.new(record)
#   puts "#{bf.code} #{bf.type} #{bf.level} #{bf.fixed}"
#   value = tmap[bf.code]
#   accumulator << value
# end

#to_field "author_facet", extract_marc("100abcd:110ab:111ab:700abcd:710ab:711ab")

