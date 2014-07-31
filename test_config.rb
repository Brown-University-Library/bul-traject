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

require 'traject/macros/marc_format_classifier'
extend Traject::Macros::MarcFormats

#Format.new(..)  extende the MarcFormatClassifier to meet Brown needs.
#We will use a single format.
class Format < Traject::Macros::MarcFormatClassifier

  #We want to reuse the logic from the
  def formats(options = {})
    options = {:default => "Other"}.merge(options)
    formats = []
    formats.concat genre
    formats << "Manuscript/Archive" if manuscript_archive?
    #formats << "Microform" if microform?
    #formats << "Online"    if online?

    # In our own data, if it's an audio recording, it might show up
    # as print, but it's probably not.
    #formats << "Print"     if print? && ! (formats.include?("Non-musical Recording") || formats.include?("Musical Recording"))

    # If it's a Dissertation, we decide it's NOT a book
    if thesis?
      formats.delete("Book")
      formats << "Dissertation/Thesis"
    end

    if proceeding?
      formats <<  "Conference"
    end

    if formats.empty?
      formats << options[:default]
    end

    return formats[0] || nil
  end
end

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
to_field "id" do |record, accumulator|
    #III record numbers
    id_spec = Traject::MarcExtractor.cached('907a')
    value = id_spec.extract(record).first
    accumulator << value.slice(1..8)
end

to_field "title", extract_marc('245a')


format_map = Traject::TranslationMap.new('format_map')
# Various librarians like to have the actual 008 language code around
to_field 'format' do |record, accumulator|
  # content_type_spec = Traject::MarcExtractor.cached('337a')
  # value = content_type_spec.extract(record).first
  # unless value.nil?
  #   accumulator << value
  #   next
  # end
  bf = Format.new(record).formats
  unless bf.nil?
    accumulator << bf
    next
  end
  puts 'still here'
  leader06 = record.leader.slice(6)
  leader08 = record.leader.slice(8)
  leader67 = record.leader.slice(6..7)
  value = format_map[leader67] || format_map[leader06] || leader67
  accumulator << value
end

#III record numbers
#id_spec = Traject::MarcExtractor.cached('907a')
#value = id_spec.extract(record)
#accumulator << value[0].slice(1..8)