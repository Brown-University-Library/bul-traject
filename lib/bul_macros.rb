require 'json'
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

  def get_505_enhanced_data field
    chapters = []
    chapter = {'authors' => []}
    field.subfields.each do |subfield|
      if subfield.code == 't'
        chapter['title'] = subfield.value
      end
      if subfield.code == 'r'
        chapter['authors'] << subfield.value.gsub('--', '').strip
      end
      if subfield.code == 'g'
        chapter['misc'] = subfield.value
      end
      #see if this subfield is the end of the chapter
      if subfield.value.end_with?(' --')
        chapters << chapter
        chapter = {'authors' => []}
      end
    end
    chapters << chapter
    chapters
  end

  def get_505_basic_data field
    chapters = []
    field.subfields.each do |subfield|
      if subfield.code == 'a'
        list_of_chapters = subfield.value.split('--')
        list_of_chapters.each do |chapter|
          chapter_info = {'authors' => [], 'title' => chapter.strip}
          chapters << chapter_info
        end
      end
    end
    chapters
  end

  def get_toc_505_info record
    extractor = MarcExtractor.new("505")
    toc_505_chapters = []
    extractor.each_matching_line(record) do |field, spec|
      if field.indicator2 == '0'
        toc_505_chapters += get_505_enhanced_data(field)
      else
        toc_505_chapters += get_505_basic_data(field)
      end
    end
    if toc_505_chapters.empty?
      nil
    else
      JSON.generate(toc_505_chapters)
    end
  end

  def get_toc_970_info record
    extractor = MarcExtractor.new("970")
    toc_970_chapters = []
    extractor.each_matching_line(record) do |field, spec|
      chapter = {'authors' => [], 'indent' => field.indicator2}
      field.subfields.each do |subfield|
        if subfield.code == 'l'
          chapter['label'] = subfield.value
        end
        if subfield.code == 't'
          chapter['title'] = subfield.value
        end
        if ['c', 'd', 'e'].include? subfield.code
          chapter['authors'] << subfield.value
        end
        if subfield.code == 'p'
          chapter['page'] = subfield.value
        end
      end
      toc_970_chapters << chapter
    end
    if toc_970_chapters.empty?
      nil
    else
      JSON.generate(toc_970_chapters)
    end
  end

  def get_toc_970_indexing record, accumulator
    extractor = MarcExtractor.new("970")
    extractor.each_matching_line(record) do |field, spec|
      if field.indicator1 == '1'
        field.subfields.each do |subfield|
          if ['f', 't'].include? subfield.code
            accumulator << subfield.value
          end
        end
      end
    end
  end

  def get_field_info_no_author field, title_subfields
    field_info = {'title' => []}
    full_title = ''
    field.subfields.each do |subfield|
      if title_subfields.include? subfield.code
        full_title += " #{subfield.value}"
        title_info = {'display' => subfield.value.strip, 'query' => full_title.strip}
        field_info['title'] << title_info
      end
    end
    field_info
  end

  def get_new_field_info field, author_subfields, title_subfields
    field_info = {'author' => '', 'title' => []}
    full_title = ''
    field.subfields.each do |subfield|
      if author_subfields.include? subfield.code
        field_info['author'] += " #{subfield.value}"
      end
      if title_subfields.include? subfield.code
        full_title += " #{subfield.value}"
        title_info = {'display' => subfield.value.strip, 'query' => full_title.strip}
        field_info['title'] << title_info
      end
    end
    field_info['author'].strip!
    field_info['author'].chomp!(',')
    field_info['author'].chomp!('.')
    field_info
  end

  def get_uniform_titles_info record
    extractor_130 = MarcExtractor.new("130")
    uniform_titles = []
    extractor_130.each_matching_line(record) do |field, spec|
      title_subfields = ['a','d','f','g','k','l','m','n','o','p','r','s','t']
      field_info = get_field_info_no_author(field, title_subfields)
      if ! field_info['title'].empty?
        uniform_titles << field_info
      end
    end
    if uniform_titles.empty?
      nil
    else
      JSON.generate(uniform_titles)
    end
  end

  def get_uniform_title_author_info record
    extractor_240 = MarcExtractor.new("240")
    uniform_titles = []
    extractor_240.each_matching_line(record) do |field, spec|
      title_subfields = ['a','d','f','g','k','l','m','n','o','p','r','s']
      field_info = get_field_info_no_author(field, title_subfields)
      if ! field_info['title'].empty?
        uniform_titles << field_info
      end
    end
    if uniform_titles.empty?
      nil
    else
      JSON.generate(uniform_titles)
    end
  end

  def get_uniform_related_works_info record
    uniform_related_works = []
    extractor_730 = MarcExtractor.new("730")
    extractor_700 = MarcExtractor.new("700")
    extractor_710 = MarcExtractor.new("710")
    extractor_711 = MarcExtractor.new("711")
    extractor_730.each_matching_line(record) do |field, spec|
      author_subfields = []
      title_subfields = ['a','d','f','g','k','l','m','n','o','p','r','s','t']
      field_info = get_new_field_info(field, author_subfields, title_subfields)
      if ! field_info['title'].empty?
        uniform_related_works << field_info
      end
    end
    extractor_700.each_matching_line(record) do |field, spec|
      author_subfields = ['a', 'b', 'c', 'd', 'q' 'u']
      title_subfields = ['f', 'k', 'l', 'm', 'n', 'o', 'p', 'r', 's', 't', 'v']
      field_info = get_new_field_info(field, author_subfields, title_subfields)
      if ! field_info['title'].empty?
        uniform_related_works << field_info
      end
    end
    extractor_710.each_matching_line(record) do |field, spec|
      author_subfields = ['a', 'b', 'c', 'd', 'g', 'n' 'u']
      title_subfields = ['f', 'k', 'l', 'm', 'o', 'r', 's', 't', 'v']
      field_info = get_new_field_info(field, author_subfields, title_subfields)
      if ! field_info['title'].empty?
        uniform_related_works << field_info
      end
    end
    extractor_711.each_matching_line(record) do |field, spec|
      author_subfields = ['a', 'c', 'd', 'g', 'n' 'u']
      title_subfields = ['f', 'k', 'l', 'p', 't']
      field_info = get_new_field_info(field, author_subfields, title_subfields)
      if ! field_info['title'].empty?
        uniform_related_works << field_info
      end
    end
    if uniform_related_works.empty?
      nil
    else
      JSON.generate(uniform_related_works)
    end
  end

end
