#
#Brown MARC to Solr indexing
#Uses traject: https://github.com/traject-project/traject
#

#Check if we are using jruby and store.
is_jruby = RUBY_ENGINE == 'jruby'
if is_jruby
  require 'traject/marc4j_reader'
end

require 'lcsort'

#Translation maps.
# './lib/translation_maps/'
$:.unshift  "#{File.dirname(__FILE__)}/lib"

require 'traject/macros/marc21_semantics'
extend  Traject::Macros::Marc21Semantics

require 'traject/macros/marc_format_classifier'
extend Traject::Macros::MarcFormats

#local macros
require 'bul_macros'
extend BulMacros

#local utils
require 'bul_utils'
require 'bul_format'

# Setup
settings do
  store "log.batch_progress", 10_000
  provide "solr.url", ENV['SOLR_URL']
  #Use Marc4JReader and solrj writer when available.
  if is_jruby
    provide "reader_class_name", "Traject::Marc4JReader"
    provide "marc4j_reader.source_encoding", "UTF-8"
    provide "solrj_writer.commit_on_close", "true"
    # Use more threads on local box.
    if ENV['TRAJECT_ENV'] == "devbox"
      provide 'processing_thread_pool', 8
    else
      provide 'processing_thread_pool', 3
    end
  end
end

logger.info RUBY_DESCRIPTION

each_record do |rec, context|
  if suppressed(rec) == true
    context.skip!("Skipping suppressed record")
  end
  #We will use this twice so hang on to it.
  context.clipboard[:is_online] = is_online(rec)
end

#Brown record id
to_field "id", record_id

#Brown last updated date
to_field "updated_dt", updated_date

#Identifiers
to_field 'isbn_t', extract_marc('020a:020z')
to_field 'issn_t', extract_marc("022a:022l:022y:773x:774x:776x", :separator => nil)
to_field 'oclc_t', oclcnum('001:035a:035z')

# Title fields
title_fields = '100tflnp:110tflnp:111tfklpsv:130adfklmnoprst:210ab:222ab:240adfklmnoprs:242abnp:' +
  '245abfgknp:246abnp:247abnp:505t:700fklmnoprstv:710fklmorstv:711fklpt:730adfklmnoprstv:740ap'
title_lambda = extract_marc(title_fields, :trim_punctuation => true)
to_field "title_t" do |rec, acc, context|
  values = []
  title_lambda.call(rec,values,nil)
  values.each do |value|
    acc << value
    value_norm = intl_char_norm(value)  # custom character normalization
    if value_norm != value
      acc << value_norm
    end
  end
end

to_field 'title_display', extract_marc('245abfgknp', :first=>true, :trim_punctuation => true)
to_field 'title_vern_display', extract_marc('245abfgknp', :alternate_script=>:only, :trim_punctuation => true, :first=>true)
to_field 'title_series_t', extract_marc(%w(
  400flnptv
  410flnptv
  411fklnptv
  440ap
  490a
  800abcdflnpqt
  810tflnp
  811tfklpsv
  830adfklmnoprstv
  ),
  :trim_punctuation => true
)
to_field "title_sort", marc_sortable_title


# If we want a specific field to mark course reserve records we
# could do something like this:
#
# to_field "course_reserve" do |record, accumulator, context|
#   extractor = MarcExtractor.new("998a", :first => true)
#   val = extractor.extract(record).first
#   if val == "xxxxx"
#     accumulator << "YES"
#   end
# end

# Uniform Titles
to_field 'uniform_titles_display' do |record, accumulator, context|
  info = get_uniform_titles_info(record)
  if !info.nil?
    accumulator << info
  end
end
to_field 'new_uniform_title_author_display' do |record, accumulator, context|
  info = get_uniform_title_author_info(record)
  if !info.nil?
    accumulator << info
  end
end
to_field 'uniform_related_works_display' do |record, accumulator, context|
  info = get_uniform_related_works_info(record)
  if !info.nil?
    accumulator << info
  end
end

# Author fields
to_field "author_display", extract_marc("100abcdq:110abcd:111abcd", :first=>true, :trim_punctuation => true)
to_field "author_vern_display", extract_marc('100abcdq:110abcd:111abcd', :alternate_script=>:only, :trim_punctuation => true, :first=>true)
to_field "author_addl_display", extract_marc('700abcd:710ab:711ab', :trim_punctuation => true)

author_lambda = extract_marc('100abcdq:110abcd:111abcdeq', :trim_punctuation => true)
to_field "author_t" do |rec, acc, context|
  values = []
  author_lambda.call(rec,values,nil)
  values.each do |value|
    acc << value
    value_norm = intl_char_norm(value)  # custom character normalization
    if value_norm != value
      acc << value_norm
    end
  end
end

to_field 'author_addl_t', extract_marc("700abcdq:710abcd:711abcdeq:810abc:811aqdce")
to_field "author_sort", extract_marc("100abcd:110abcd:111abc:110ab:700abcd:710ab:711ab", :first=>true)

#
# - Publication details fields
#
to_field "published_display", extract_marc("260a", :trim_punctuation=>true)
to_field "published_vern_display",  extract_marc("260a", :alternate_script => :only)
#Display physical information.
to_field 'physical_display', extract_marc('300abcefg:530abcd')
to_field "abstract_display", extract_marc("520a", :first=>true)
to_field "toc_display" do |record, accumulator, context|
  info = get_toc_505_info(record)
  if !info.nil?
    accumulator << info
  end
end
to_field "toc_970_display" do |record, accumulator, context|
  info = get_toc_970_info(record)
  if !info.nil?
    accumulator << info
  end
end

to_field "pub_date", marc_publication_date

# Currently the URL and the label are on separate fields
# (url_fulltext_display and url_suppl_display) and therefore
# we cannot handle more than one accurately since we cannot
# guarantee that they are in the same order.
#
# These two fields will be removed once we updated the client
# to use the new JSON field url_fulltext_json_s (see below)
to_field "url_fulltext_display" do |record, accumulator, context|
  if context.clipboard[:is_online]
    values = []
    x856u = extract_marc("856u")
    x856u.call(record, values, nil)
    if values.count > 0
      # Use the 856 value (notice that we only support one value)
      accumulator << values[0]
    else
      # No 856 value, see if we have a BDR link
      bib = record_id.call(record, []).first
      bdr_url = brd_items_cache()[bib]
      if bib != nil && bdr_url != nil
        accumulator << bdr_url
      end
    end
  end
end

to_field "url_suppl_display" do |record, accumulator, context|
  if context.clipboard[:is_online]
    values = []
    x856z = extract_marc("856z")
    x856z.call(record, values, nil)
    if values.count > 0
      # Use the 856 value (notice that we only support one value)
      accumulator << values[0]
    else
      # Nothing to do - let Josiah use the default "Available Online" label.
    end
  end
end

# New field to store full text links as a single JSON string
# that the client can parse. This allows us to handle more than
# one full text link and its associated text accurately.
to_field "url_fulltext_json_s" do |record, accumulator, context|
  values = []
  link_856 = false

  # Process the URLs from the 856 field
  # (We add these links to Solr regardless of whether the
  # record is marked as online or not)
  f856 = record.select {|f| f.tag == "856"}
  f856.each do |f|
    u = subfield_value(f, "u") || ""
    z = subfield_value(f, "z") || "Available Online"
    f3 = subfield_value(f, "3")
    if u.strip != ""
      values << online_avail_data(u, z, f3)
      link_856 = true
    end
  end

  # Only add these links manually only if we did not add them
  # through MARC 856.
  if context.clipboard[:is_online] && !link_856
    # Add BRD URLs from our local cache.
    bib = record_id.call(record, []).first
    bdr_url = brd_items_cache()[bib]
    if bdr_url != nil
      values << online_avail_data(bdr_url, "Available Online")
    end

    # Add ProQuest URLs from our local cache.
    proquest_url = proquest_items_cache()[bib]
    if proquest_url != nil
      values << online_avail_data(proquest_url, "Full text available from ProQuest Dissertations & Theses Global (Brown community)")
    end
  end

  if values.count > 0
    accumulator << values.to_json
  end
end

#Online true/false
to_field "online_b" do |record, accumulator, context|
  accumulator << context.clipboard[:is_online]
end

#Access facet
to_field "access_facet" do |record, accumulator, context|
  online = context.clipboard[:is_online]
  if online == true
    val = "Online"
  else
    val = "At the library"
  end
  accumulator << val
end


#
# - Facet fields
#

#Custom logic for format
to_field 'format' do |record, accumulator|
  tmap = Traject::TranslationMap.new('format')
  bf = Format.new(record)
  value = tmap[bf.code]
  accumulator << value
end

#Author - local macro
to_field "author_facet", author_facet
#Language
to_field 'language_facet', marc_languages("008[35-37]:041a:041d:041e:041j")

#Buildings - Unique list of 945s sf l processed through the translation map.
to_field "building_facet", extract_marc('945l') do |record, acc|
  acc.map!{|code| map_code_to_building(code)}.uniq!
end

# There can be 0-N location codes per BIB record
# because the location code is at the item level.
to_field "location_code_t", extract_marc('945l', :trim_punctuation => true)

to_field "region_facet", marc_geo_facet
to_field "topic_facet", extract_marc("650a:690a", :trim_punctuation => true)



#
# - Search fields
#

#Subject search.  See: https://github.com/billdueber/ht_traject/blob/master/indexers/common.rb
to_field "subject_t", extract_marc(%w(
  600a  600abcdefghjklmnopqrstuvxyz
  610a  610abcdefghklmnoprstuvxyz
  611a  611acdefghjklnpqstuvxyz
  630a  630adefghklmnoprstvxyz
  648a  648avxyz
  650a  650abcdevxyz
  651a  651aevxyz
  653a  654abevyz
  654a  655abvxyz
  655a  656akvxyz
  656a  657avxyz
  657a  658ab
  658a  662abcdefgh
  690a   690abcdevxyz
  ), :trim_punctuation=>true)

#Callnumber
callnumber_spec = "050ab:090ab:091ab:092ab:096ab:099ab"
to_field "callnumber_t", extract_marc(callnumber_spec, :trim_punctuation => true)
to_field "callnumber_ss", extract_marc(callnumber_spec, :trim_punctuation => false) do |record, acc|
  new_callnumbers = callnumbers_from_945(record)
  new_callnumbers.each do |callnumber|
    acc << callnumber
  end
end

to_field "callnumber_std_ss" do |record, acc|

  # Get the call number as usual (see above)...
  callnumbers = []
  cn_lambda = extract_marc(callnumber_spec, :trim_punctuation => false)
  cn_lambda.call(record, callnumbers, nil)
  new_callnumbers = callnumbers_from_945(record)

  # ...and then calculate a "standard" format by tokenizing
  # the values. This field will be used to try to find
  # callnumbers even if the punctuation is different.
  all = (callnumbers + new_callnumbers).map {|x| x.upcase.strip}
  all.sort.uniq.each do |cn|
    if cn != nil
      cn_std = cn.scan(/[A-Z]+|\d+/).join("|")
      if cn_std != ""
        acc << cn_std
      end
    end
  end
end


to_field "callnumber_norm_ss" do |record, acc|

  # Get the call number as usual (see above)...
  bib_callnumbers = []
  cn_lambda = extract_marc(callnumber_spec, :trim_punctuation => false)
  cn_lambda.call(record, bib_callnumbers, nil)
  item_callnumbers = callnumbers_from_945(record)

  # ...and then calculate a normalized value for each of them
  all = (bib_callnumbers + item_callnumbers).map {|x| x.upcase.strip}
  all.compact.uniq.sort.each do |cn|
    cn_norm = Lcsort.normalize(cn)
    if cn_norm != nil
      acc << cn_norm
    end
  end
end

#Text - for search
to_field "text", extract_all_marc_values(:from=>'090', :to=>'900')
to_field "text" do |record, accumulator, context|
    get_toc_970_indexing(record, accumulator)
end

to_field "marc_display", serialized_marc(:format => "json", :allow_oversized => true)

# Bookplate information is on 935a (bib level) and
# 945f (item level). Each item in a BIB record can
# have a different book plate codes.
#
# There is also bookplate information in the "checkin"
# records but we do not get that data in our MARC files
# so we cannot take those records into account. *sad trombone*s
#
# TODO: remove the _facet field, or we could repurpose this field to
# have a shortened version of the bookplate code, one without the
# "bookplate_" prefix and without the purchased_yyyy suffix (where
# yyyy is the year)
to_field "bookplate_code_facet", extract_marc("945f")
to_field "bookplate_code_ss", extract_marc("935a:945f")

lang_lambda = marc_languages("008[35-37]:041a:041d:041e:041j")

# Authors for CJK languages
author_vern_lambda = extract_marc('100abcdq:110abcd:111abcd:700abcd:710ab:711ab', :alternate_script=>:only)
to_field "author_txt_cjk" do |rec, acc, context|
  langs = lang_lambda.call(rec,[])
  if langs.count == 0 || (langs.count == 1 && langs[0] == "English")
    # nothing to do for 80% of our materials
  else
    is_cjk = langs.include?("Chinese") || langs.include?("Japanese") || langs.include?("Korean")
    if is_cjk
      authors_cjk = []
      author_vern_lambda.call(rec,authors_cjk,nil)
      authors_cjk.each do |author|
        acc << author
      end
    end
  end
end

# Title for CJK languages
title_fields = "100tflnp:110tflnp:111tfklpsv:130adfklmnoprst:210ab:222ab:" +
  "240adfklmnoprs:242abnp:245abfgknp:246abnp:247abnp:260a:490a:505t:700fklmnoprstv:710fklmorstv" +
  "711fklpt:730adfklmnoprstv:740ap"
title_vern_lambda = extract_marc(title_fields, :alternate_script=>:only)
to_field "title_txt_cjk" do |rec, acc, context|
  langs = lang_lambda.call(rec,[])
  if langs.count == 0 || (langs.count == 1 && langs[0] == "English")
    # nothing to do for 80% of our materials
  else
    is_cjk = langs.include?("Chinese") || langs.include?("Japanese") || langs.include?("Korean")
    if is_cjk
      titles_cjk = []
      title_vern_lambda.call(rec,titles_cjk,nil)
      titles_cjk.each do |title|
        acc << title
      end
    end
  end
end
