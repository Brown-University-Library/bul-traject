# encoding: UTF-8
=begin
These test the entire traject mapping and output process.
They are quite slow since they start up traject for each record tested.
Should consider replacing these.
=end

require 'json'

def trajectify(fixture_name)
    o = '/tmp/tmp.json'
    i = File.expand_path("../fixtures/#{fixture_name}.mrc",__FILE__)
    c = File.expand_path('../../config.rb',__FILE__)
    system "traject -c #{c} #{i} -w Traject::JsonWriter -o #{o}"
    JSON.parse(IO.read(o))
end

describe 'From config.rb' do
  before(:all) do

  @book_880 = trajectify('book_880')
  @newspaper = trajectify('newspaper')
  @journal = trajectify('journal')

  end

  describe 'the id field' do
    it 'has exactly 1 value' do
      expect(@book_880['id'].length).to eq 1
    end
    it 'has the correct id' do
      expect(@book_880['id'][0]).to eq 'b5526960'
      expect(@newspaper['id'][0]).to eq 'b4086450'
    end
  end

  describe 'the titles' do
    it 'has the title_display' do
      expect(@book_880['title_display'][0]).to eq 'Fan zui diao cha tong ji xue'
    end

    #To do: figure out how to git this to pass on windows, if possible.
    if (ENV['OS'] != 'Windows_NT')
      it 'has the title_vern_display' do
       expect(@book_880['title_vern_display'][0]).to eq '犯罪調查統計學'
      end
    end
  end

  describe 'the format' do
    it 'has the format' do
      expect(@book_880['format'][0]).to eq 'Book'
    end
    it 'newspaper has correct format' do
      expect(@newspaper['format'][0]).to eq 'Periodical Title'
    end
    it 'journal has correct format' do
      expect(@journal['format'][0]).to eq 'Periodical Title'
    end
    #it 'dissertation has correct format' do
    #  expect(@dissertation['format'][0]).to eq 'Dissertation or Thesis'
    #end
  end

  describe 'the callnumber' do
   it 'has the correct callnumber' do
     expect(@book_880['callnumber_t'][0]).to eq 'HV6018 .Y35'
   end

   it 'has the correct 050 callnumber' do
     record_970 = trajectify('970record')
     expect(record_970['callnumber_t'][0]).to eq 'HV1431 .E25 1993'
   end
  end

end


describe 'From journal multiple items' do
  before do
    @rec = trajectify('journal_multiple_items')
  end

  it 'the buildings' do
    buildings = @rec['building_facet']
    expect(buildings).to include 'Rockefeller'
    expect(buildings).to include 'Annex'
    #Make sure there aren't duplicates in the building_facet
    expect(buildings.uniq.length).to eq (buildings.length)
  end

end


describe 'From has abstract' do
  before do
    #@rec = trajectify('has_abstract')
    @rec_no_abstract = trajectify('ejournal')
  end

  # it 'correctly has the abstract' do
  #   abstract = @rec['abstract_display'][0]
  #   expect(abstract).to include 'Martin Luther King'
  # end

  it 'correctly does not have an abstract' do
    abstract = @rec_no_abstract['abstract_display']
    expect(abstract).to be_nil
  end

end


describe "Identifies OCLC number correctly" do
  it 'book has correct OCLC number' do
    rec = trajectify('book_880')
    oclc = rec['oclc_t'][0]
    expect(oclc).to eq "22503825"
  end
end

describe "Identifying format" do
  it 'archive/manuscript is identified' do
    rec = trajectify('archive_manuscript')
    expect(rec['format'][0]).to eq 'Archives/Manuscripts'
  end
end


describe "author_t parsed properly" do
  it "finds sf q" do
    rec = trajectify('map')
    actual = ["Hayes, C. W. (Charles Willard), 1859-1916"]
    expect(rec['author_t']).to eq actual
  end
end


describe "title_t parsed properly" do
  it "finds multiple subfields" do
    rec = trajectify('gothic-classics-700t')
    title_t = rec['title_t']
    #505t
    expect(title_t).to include "I've a pain in my head [poem]"
    #700ts
    expect(title_t).to include "Northanger Abbey"
    expect(title_t).to include "Oval portrait"
  end
end

describe "970 table of contents processing" do
  before do
    @toc_970 = trajectify('970record')
  end

  it "doesn't have a 970 key if there's no info" do
    @book_880 = trajectify('book_880')
    expect(@book_880['id'][0]).to eq 'b5526960'
    expect(@book_880['toc_970_display']).to be nil
  end

  it "has the id" do
    expect(@toc_970['id'][0]).to eq "b2105985"
  end

  it "has the correct 970 information" do
    toc_970_text = @toc_970['toc_970_display'][0]
    expect(toc_970_text).not_to be nil
    toc_970_info = JSON.parse(toc_970_text)
    expect(toc_970_info[0]['label']).to be nil
    expect(toc_970_info[0]['title']).to eq 'Forward'
    expect(toc_970_info[0]['authors']).to eq ['Anne C. Peterson']
    expect(toc_970_info[2]['indent']).to eq '2'
    expect(toc_970_info[2]['label']).to eq '1'
    expect(toc_970_info[2]['title']).to eq 'Early Adolescence: Toward an Agenda for the Integration of Research, Policy, and Intervention'
    expect(toc_970_info[2]['page']).to eq '1'
    expect(toc_970_info[3]['authors']).to eq ['Kevin W. Allison', 'Richard M. Lerner']
  end

  it "indexes 970 info in text field for searching" do
    text = @toc_970['text']
    expect(text).to include 'Allison, Kevin W.'
    expect(text).not_to include 'Kevin W. Allison'
    expect(text).to include 'Early Adolescent Family Formation'
    expect(text).not_to include 'Forward'
  end
end

describe "505 table of contents processing" do

  it "doesn't have a 505 key if there's no info" do
    book_880 = trajectify('book_880')
    expect(book_880['id'][0]).to eq 'b5526960'
    expect(book_880['toc_display']).to be nil
  end

  it "indexes a 505 basic field" do
    toc_record = trajectify('505record')
    expect(toc_record['id'][0]).to eq('b4758876')
    toc_info = JSON.parse(toc_record['toc_display'][0])
    expect(toc_info[0]['title']).to eq('Gold : the emperor\'s dream')
    expect(toc_info[-1]['title']).to eq('Orange : European revolutions.')
  end

  it "indexes 505 titles/chapters field" do
    toc_record = trajectify('505record_titles_authors')
    expect(toc_record['id'][0]).to eq('b1003703')
    toc_info = JSON.parse(toc_record['toc_display'][0])
    expect(toc_info[0]['title']).to eq('Myth and reason: an introduction /')
    expect(toc_info[0]['authors']).to eq(['Walter D. Wetzels'])
    expect(toc_info[-1]['title']).to eq('Myth and reason?: a round-table discussion.')
    expect(toc_info[-1]['authors']).to eq([])
    expect(toc_info[-1]['misc']).to eq('Appendix:')
  end
end

describe "index uniform titles" do

  it "indexes 130 & 730 field" do
    record_130 = trajectify('uniform_130')
    expect(record_130['id'][0]).to eq('b1004749')
    expect(record_130['title_display'][0]).to eq('Codex Climaci rescriptus')
    uniform_titles_info = JSON.parse(record_130['uniform_titles_display'][0])
    expect(uniform_titles_info[0]['title'][0]['display']).to eq('Bible. N.T. Syriac (Palestinian) Selections. 1909.')
    expect(uniform_titles_info[0]['title'][0]['query']).to eq('Bible. N.T. Syriac (Palestinian) Selections. 1909.')
    uniform_related_info = JSON.parse(record_130['uniform_related_works_display'][0])
    expect(uniform_related_info[0]['author']).to eq('')
    expect(uniform_related_info[0]['title'][0]['display']).to eq('Bible.')
    expect(uniform_related_info[0]['title'][0]['query']).to eq('Bible.')
    expect(uniform_related_info[0]['title'][1]['display']).to eq('New Testament.')
    expect(uniform_related_info[0]['title'][1]['query']).to eq('Bible. New Testament.')
    expect(uniform_related_info[0]['title'][2]['display']).to eq('Greek.')
    expect(uniform_related_info[0]['title'][2]['query']).to eq('Bible. New Testament. Greek.')
    expect(uniform_related_info[0]['title'][3]['display']).to eq('Selections.')
    expect(uniform_related_info[0]['title'][3]['query']).to eq('Bible. New Testament. Greek. Selections.')
    expect(uniform_related_info[1]['author']).to eq('Lewis, Agnes Smith, 1843-1926')
    expect(uniform_related_info[1]['title'][0]['display']).to eq('Codex Climaci rescriptus.')
    expect(uniform_related_info[1]['title'][0]['query']).to eq('Codex Climaci rescriptus.')
  end

  it "indexes 240 & 7xx fields" do
    record_240 = trajectify('uniform_240')
    expect(record_240['id'][0]).to eq('b6354523')
    new_uniform_title_author_info = JSON.parse(record_240['new_uniform_title_author_display'][0])
    expect(new_uniform_title_author_info[0]['title'][0]['display']).to eq('Musicals.')
    expect(new_uniform_title_author_info[0]['title'][0]['query']).to eq('Musicals.')
    expect(new_uniform_title_author_info[0]['title'][1]['display']).to eq('Selections.')
    expect(new_uniform_title_author_info[0]['title'][1]['query']).to eq('Musicals. Selections.')
    expect(new_uniform_title_author_info[0]['title'][2]['display']).to eq('Vocal scores.')
    expect(new_uniform_title_author_info[0]['title'][2]['query']).to eq('Musicals. Selections. Vocal scores.')
    uniform_related_works_info = JSON.parse(record_240['uniform_related_works_display'][0])
    expect(uniform_related_works_info[0]['author']).to eq('')
    expect(uniform_related_works_info[0]['title'][0]['display']).to eq('Dick Tracy (Motion picture : 1990)')
    expect(uniform_related_works_info[0]['title'][0]['query']).to eq('Dick Tracy (Motion picture : 1990)')
    expect(uniform_related_works_info[1]['author']).to eq('Sondheim, Stephen')
    expect(uniform_related_works_info[1]['title'][0]['display']).to eq('Anyone can whistle.')
    expect(uniform_related_works_info[1]['title'][0]['query']).to eq('Anyone can whistle.')
    expect(uniform_related_works_info[1]['title'][1]['display']).to eq('Anyone can whistle.')
    expect(uniform_related_works_info[1]['title'][1]['query']).to eq('Anyone can whistle. Anyone can whistle.')
    expect(uniform_related_works_info[1]['title'][2]['display']).to eq('Vocal score.')
    expect(uniform_related_works_info[1]['title'][2]['query']).to eq('Anyone can whistle. Anyone can whistle. Vocal score.')
    expect(uniform_related_works_info[-1]['author']).to eq('Sondheim, Stephen')
    expect(uniform_related_works_info[-1]['title'][0]['display']).to eq('Sweeney Todd.')
    expect(uniform_related_works_info[-1]['title'][0]['query']).to eq('Sweeney Todd.')
    expect(uniform_related_works_info[-1]['title'][-1]['display']).to eq('Vocal score.')
    expect(uniform_related_works_info[-1]['title'][-1]['query']).to eq('Sweeney Todd. Not while I\'m around. Vocal score.')
  end

end
