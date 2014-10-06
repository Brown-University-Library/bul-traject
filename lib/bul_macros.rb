require 'traject/macros/marc21'
require 'traject/marc_extractor'
#shortcut
Marc21 = Traject::Macros::Marc21
MarcExtractor = Traject::MarcExtractor

module BulMacros

  #Find the record id, remove leading . and strip trailing check digit.
  def record_id
    extractor = MarcExtractor.new("907a", :first => true)
    lambda do |record, accumulator|
      accumulator << extractor.extract(record).first.slice(1..8)
    end
  end

  # #Returns true if a record is suppressed.
  # #
  # #Identify whether a given record is suppressed.  Local system uses
  # #field 998 subfield e with a value of n to indicate the item is
  # #suppressed.
  # def suppressed
  #   extractor = MarcExtractor.new("998e", :first => true)
  #   lambda do |record, accumulator|
  #     val = extractor.extract(record).first
  #     if val == 'n'
  #       accumulator << true
  #     end
  #   end
  # end

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
end
