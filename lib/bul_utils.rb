require 'traject'
#shortcut
MarcExtractor = Traject::MarcExtractor

def run_extractor(record, extractor)
  values = extractor.collect_matching_lines(record) do |field, spec, extractor|
    extractor.collect_subfields(field, spec)
  end.compact
  return values
end

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
  item_locs = run_extractor(record, MarcExtractor.new("945l"))
  item_locs.each do |val|
    if val.start_with?("es")
      return true
    end
  end
  # Also check bib location 998 a
  bib_locs = run_extractor(record, MarcExtractor.new("998a", :first =>true))
  bib_locs.each do |val|
    if val == "es001"
      return true
    end
  end
  return false
end

#Returns date in UTC format for Solr
#
#https://github.com/sunspot/sunspot/blob/ec64df6a526d738f9f77c039679b344f908d3298/sunspot/lib/sunspot/type.rb#L244
#https://cwiki.apache.org/confluence/display/solr/Working+with+Dates
def solr_date(date)
  return Time.utc(date.year, date.mon, date.mday).iso8601()
end

def map_code_to_building code
  bldg = Traject::TranslationMap.new("buildings")[code.downcase]
  if bldg.nil?
    bldg = Traject::TranslationMap.new("buildings")[code.downcase[0]]
  end
  bldg
end
