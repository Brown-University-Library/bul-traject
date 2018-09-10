require 'traject'
# require 'byebug'
#shortcut
MarcExtractor = Traject::MarcExtractor

# Gets the record ID (MARC 907a) form the record passed as a parameter.
# Notice that BulMacros::record_id uses an available record variable on scope.
def id_from_record(record)
  f907 = record.find {|f| f.tag == "907"}
  f907.subfields.find {|s| s.code == "a"}.value
end

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
  # if val == 'n'
  #   extractor = MarcExtractor.new("998a", :first => true)
  #   val = extractor.extract(record).first
  #   if val == "xxxxx"
  #     # Don't suppress the record if its location (998a) indicates
  #     # RESERVES (xxxxx). These are items used for course reserves
  #     # and students search for them in Josiah.
  #     return false
  #   end
  #   return true
  # end
  # return false
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
  bldg = Traject::TranslationMap.new("buildings")[code.strip.downcase]
  if bldg.nil?
    bldg = Traject::TranslationMap.new("buildings")[code.downcase[0]]
  end
  bldg
end

# Builds a callnumber from the subfield values passed.
# An empty string means no callnumber was built.
def build_callnumber(a, b, c, g, alternate_stem)
  if a == nil && b == nil
    ab = alternate_stem
  else
    ab = [a, b].compact.join(" ")
  end
  if g == "1"
    g = nil
  end
  if g != nil
    g = "c.#{g}"
  end
  [ab, c, g].compact.join(" ").strip
end

# Returns the vlue for a subfield for the given field.
def subfield_value(field, subfield)
  sub = field.subfields.find {|s| s.code == subfield}
  if sub.nil?
    return nil
  end
  sub.value
end

# Returns the callnumber values found on MARC 945abcg for the
# record. If the 945 does not have a and b values it uses the
# ones found on the 090ab.
def callnumbers_from_945(record)
  callnumbers = []
  # Get the and b values to use as alternates
  # TODO: do we need to consider other fields (e.g. 099)?
  values_090ab = []
  x090ab = extract_marc("090ab", :trim_punctuation => false)
  x090ab.call(record, values_090ab, nil)
  alternate_stem = values_090ab.join(" ")
  # Process the callnumbers in the 945
  f945 = record.select {|f| f.tag == "945"}
  f945.each do |f|
    a = subfield_value(f, "a")
    b = subfield_value(f, "b")
    c = subfield_value(f, "c")
    g = subfield_value(f, "g")
    callnumber = build_callnumber(a, b, c, g, alternate_stem)
    if callnumber != ""
      callnumbers << callnumber
    end
  end
  callnumbers
end


# def find_partial_callnumbers_old(record)
#   new_callnumbers = []
#
#   x090ab = extract_marc("090ab", :trim_punctuation => false)
#   x945ab = extract_marc("945ab", :trim_punctuation => false)
#   x945cg = extract_marc("945cg", :trim_punctuation => false)   # c is volume, (g is copy?)
#
#   acc_945ab = []
#   acc_945cg = []
#   x945ab.call(record, acc_945ab, nil)
#   x945cg.call(record, acc_945cg, nil)
#   # Are there partial call numbers in 945cg (i.e. without 945ab values)
#   if acc_945cg.count > 0 && acc_945ab.count == 0
#
#     acc_090ab = []
#     x090ab.call(record, acc_090ab, nil)
#     # ... but we have 090ab, let's build the complete call numbers
#     # by combining the 090ab with the 945cg
#     if acc_090ab.count > 0
#       callnumber_stem = acc_090ab.join()
#       f945 = record.select {|f| f.tag == "945"}
#       f945.each do |f|
#         c = f.subfields.find {|s| s.code == "c"}
#         g = f.subfields.find {|s| s.code == "g"}
#         # must use g.nil? rather than g != nil because g has its own ==
#         # operator defined
#         if !g.nil? && g.value == "1"
#           g = nil
#         end
#         if c.nil? && g.nil?
#           # nothing to add
#         elsif !c.nil? && g.nil?
#           new_callnumbers << callnumber_stem + " " + c.value.strip
#         elsif c.nil? && !g.nil?
#           new_callnumbers << callnumber_stem + " " + g.value.strip
#         else
#           new_callnumbers << callnumber_stem + " " + c.value.strip + " " + g.value.strip
#         end
#       end
#     end
#   end
#   new_callnumbers
# end
