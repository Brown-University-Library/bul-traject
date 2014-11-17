require 'traject/macros/marc21'
require 'traject/marc_extractor'
#shortcut
Marc21 = Traject::Macros::Marc21
MarcExtractor = Traject::MarcExtractor

require 'bul_utils'

module BulMacros

  #Find the record id, remove leading . and strip trailing check digit.
  def record_id
    extractor = MarcExtractor.new("907a", :first => true)
    lambda do |record, accumulator|
      accumulator << extractor.extract(record).first.slice(1..8)
    end
  end

  def author_facet(spec = "100abcd:110ab:111ab:700abcd:710ab:711ab")
    extractor = MarcExtractor.new(spec)

    lambda do |record, accumulator|
      values = extractor.collect_matching_lines(record) do |field, spec, extractor|
        extractor.collect_subfields(field, spec) unless (field.tag == "710" && field.indicator2 == "9")
      end.compact

      # trim punctuation
      values.collect! do |s|
        Marc21.trim_punctuation(s)
      end

      #Remove authors thatare just '.'
      values.delete_if {|v| v == '.' }

      accumulator.concat( values )
    end
  end

  #Returns date record was last updated
  #
  #Converts date string found in MARC 907 b to Ruby date obj.
  #Will return nil if date parsing fails.
  def updated_date
    extractor = MarcExtractor.new("907b", :first => true)
    lambda do |record, acc|
      datestr = extractor.extract(record).first
      begin
        date = Date.strptime(datestr, "%m-%d-%y")
        acc << solr_date(date)
      rescue ArgumentError
        yell.debug "Unable to parse datestr #{datestr}"
      end
    end
  end

end
