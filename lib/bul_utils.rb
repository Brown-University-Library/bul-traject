require 'traject'
require "json"
MarcExtractor = Traject::MarcExtractor

CLASSIC_JOSIAH_URL = "http://josiah.brown.edu/record="
NEW_JOSIAH_URL = "http://search.library.brown.edu/catalog/"

def brd_items_cache()
  @bdr_items_cache ||= begin
    if File.exists?("./data/bdr2cat.json")
      text = File.read("./data/bdr2cat.json")
      json = JSON.parse(text)
      cache = {}
      json["response"]["docs"].each do |doc|
        key = doc["cat_bib"][0..-2]
        value = doc["bdr_url"]
        cache[key] = value
      end
      cache
    else
      {}
    end
  end
end

def proquest_items_cache()
  @proquest_items_cache ||= begin
    if File.exists?("./data/proquest.tsv")
      cache = {}
      File.readlines("./data/proquest.tsv").each_with_index do |line, ix|
        tokens = line.split("\t")
        bib = tokens[0]
        proquest_id = tokens[1]
        if bib.start_with?("b")
          cache[bib] = "https://search.proquest.com/docview/#{proquest_id}?accountid=9758"
        end
      end
      cache
    else
      {}
    end
  end
end

# The input parameters usually come from MARC 856 field:
#   url is 856 u
#   note is 856 z
#   materials is 856 3
def online_avail_data(url, note, materials = nil)
    if url.start_with?(CLASSIC_JOSIAH_URL)
      url = url.gsub(CLASSIC_JOSIAH_URL, NEW_JOSIAH_URL)
    else
      url = url
      if !url.start_with?("http://") && !url.start_with?("https://")
        url = "http://#{url}"
      end
    end

    label = ""
    if note == nil && materials == nil
      label = "Available online"
    elsif note == nil && materials != nil
      label = materials
    elsif note != nil && materials == nil
      label = note
    else
      label = "#{note} (#{materials})"
    end

    {url: url, text: label}
end

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

  # =================
  # NOTE: We use the local cache files to determine if some BDR and ProQuest
  # records should be flagged as online because in the catalog the bib and
  # item information are for the physical copy of the record (hence not
  # marked as "online") and the data in the 856 with the link is not enough
  # to flag them as "online". But since these records are indeed available
  # online this extra logic makes sure they are flagged as such.
  #
  bib = record_id.call(record, []).first
  if brd_items_cache()[bib] != nil
    # We have a digitized version in the BDR
    return true
  end

  if proquest_items_cache()[bib] != nil
    # We have an online copy available through ProQuest
    return true
  end
  # =================

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
  if g == "1" || g == "0"
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

# Applies a few character normalizations to a text. This is to handle
# transformations not supported by Solr's own ICU Folding Filter
# https://lucene.apache.org/solr/guide/7_7/filter-descriptions.html
def intl_char_norm(value)
  if value.include?("ʻ")
    # This character is often found in Romanized versions of Korean names and
    # titles (e.g. "Sŏngtʻanje : Pak Tʻae-wŏn chʻangjakjip") but US users tend
    # to enter a single tick (') instead.
    return value.gsub("ʻ", "'")
  end
  value
end
