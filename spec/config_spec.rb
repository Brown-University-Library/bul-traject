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

  #Not currently indexed.
  #describe 'the callnumber' do
  #  it 'has the correct callnumber' do
  #    expect(@book_880['callnumber_t'][0]).to eq 'HV6018 .Y35'
  #  end
  #end

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
    #245
    expect(title_t).to include "Gothic classics"
    #505t
    expect(title_t).to include "I've a pain in my head [poem]"
    #700ts
    expect(title_t).to include "Northanger Abbey"
    expect(title_t).to include "Oval portrait"
  end
end

