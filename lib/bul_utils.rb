require 'traject/marc_extractor'
#shortcut
MarcExtractor = Traject::MarcExtractor

#Returns true if a record is suppressed.
#
#Identify whether a given record is suppressed.  Local system uses
#field 998 subfield e with a value of n to indicate the item is
#suppressed.
def suppressed(record)
  extractor = MarcExtractor.new("998e", :first => true)
  val = extractor.extract(record).first
  if val == 'n'
    return true
  end
end

#Returns true if record is available online
#
#Identify whether a given record is available online.
#Uses the location code found in item records.
#Brown location codes beginning with "es" indicate the item
#is available online.
def is_online(record)
  extractor = MarcExtractor.new("945l")
  values = extractor.collect_matching_lines(record) do |field, spec, extractor|
    extractor.collect_subfields(field, spec)
  end.compact
  values.each do |val|
    if val.start_with?("es")
      return true
    end
  end
  return false
end