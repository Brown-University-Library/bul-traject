require 'traject/macros/marc21'
require 'traject/marc_extractor'
#shortcut
Marc21 = Traject::Macros::Marc21
MarcExtractor = Traject::MarcExtractor

module BrownMacros
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
