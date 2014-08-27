require 'traject'
require 'traject/umich_format'

require 'lib/brown_format'

require 'bulmarc'

extend Traject::UMichFormat::Macros

$:.unshift  "#{File.dirname(__FILE__)}/lib"

# Note that we only want one id, so we'll take the first one
to_field "id" do |record, accumulator|
  #III record numbers
  id_spec = Traject::MarcExtractor.cached('907a')
  value = id_spec.extract(record)
  accumulator << value[0].slice(1..8)
end

to_field 'bib_format', umich_format
to_field 'bib_types', umich_types
to_field 'bib_formats_and_types', umich_format_and_types

to_field 'brown_format' do |record, accumulator|
  #tmap = Traject::TranslationMap.new('umich/format')
  tmap = Traject::TranslationMap.new('format')
  bru = BrownFormat.new(record)
  tcode = bru.primary
  accumulator << tmap[tcode]
end

to_field 'bulmarc_format' do |record, accumulator|
  #tmap = Traject::TranslationMap.new('umich/format')
  tmap = Traject::TranslationMap.new('format')
  bru = BulMarc::Format.new(record)
  tcode = bru.code
  accumulator << tmap[tcode]
end

#For debugging/printing.
to_field 'codes_format_and_type' do |record, accumulator|
  um = Traject::UMichFormat.new(record)
  tcode = um.format_and_types
  accumulator << tcode
end

=begin
Archives/Manuscripts
Data Files
Journal Titles
Images
Maps
Microfilm
Mixed Media
Newspaper Articles
Videos
Theses/Dissertations
=end


