# A traject file is (a) totally self-contained,
# and (b) just uses a debug writer to write things out.

# For a more complete example of indexing code, look at
# the index.rb file in this directory


# You can run this against a binary marc file 'myfile.mrc' as:
#
#     traject -c ./simplest_possible_traject_config myfile.mrc





# Set up a reader and a writer
# First we need to require the reader/writer we want

require 'traject'
require 'traject/marc4j_reader'
require 'traject/debug_writer'

#Local utils gem
require 'bulmarc'

#require 'traject/macros/marc_format_classifier'
#extend Traject::Macros::MarcFormats

#translation maps
$:.unshift  "#{File.dirname(__FILE__)}/lib"


# The add the appropriate settings
settings do
  #provide "reader_class_name", "Traject::Marc4JReader"
  provide "reader_class_name", "Traject::MarcReader"
  # Right now, logging is going to $stderr. Uncomment
  # this line to send it to a file
  # provide 'log.file', 'traject.log'
end
# Log what version of jruby/java we're using

logger.info RUBY_DESCRIPTION

# Note that we only want one id, so we'll take the first one
to_field "id" do |record, accumulator |
  accumulator << record_id(record)
end

#Brown last updated date
to_field "updated_dt" do |record, accumulator |
 accumulator << updated_date(record)
end

to_field "title", extract_marc('245a')


format_map = Traject::TranslationMap.new('format')
# Various librarians like to have the actual 008 language code around
to_field 'format' do |record, accumulator|
  # content_type_spec = Traject::MarcExtractor.cached('337a')
  # value = content_type_spec.extract(record).first
  # unless value.nil?
  #   accumulator << value
  #   next
  # end
  bf = BulMarc::Format.new(record).code
  value = format_map[bf]
  accumulator << value
end

to_field "building_facet", extract_marc('945l') do |record, acc|
  acc.map!{|code| TranslationMap.new("buildings")[code.downcase[0]]}.uniq!
end

#Brown buildings
# to_field "building_facet" do |record, accumulator |
#  accumulator << TranslationMap.new("buildings")bul_buildings(record)
# end