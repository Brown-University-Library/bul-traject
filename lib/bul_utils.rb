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