# encoding: UTF-8
=begin
These can considered integration tests that test the entire
traject mapping and output process.  They are quite slow
since they start up traject for each record tested.
=end

require 'json'

def trajectify(fixture_name)
    o = '/tmp/tmp.json'
    i = File.expand_path("../fixtures/#{fixture_name}.mrc",__FILE__)
    c = File.expand_path('../../bul_index.rb',__FILE__)
    system "traject -c #{c} #{i} -w Traject::JsonWriter -o #{o}"
    JSON.parse(IO.read(o))
end

describe 'From config.rb' do
  before(:all) do

  @book_880 = trajectify('book_880')
  @newspaper = trajectify('newspaper')
  @journal = trajectify('journal')
  @dissertation = trajectify('dissertation')
  @dissertation = trajectify('journal_multiple_items')

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

    it 'has the title_vern_display' do
      expect(@book_880['title_vern_display'][0]).to eq '犯罪調查統計學'
    end
  end

  describe 'the format' do
    it 'has the format' do
      expect(@book_880['format'][0]).to eq 'Book'
    end
    it 'newspaper has correct format' do
      expect(@newspaper['format'][0]).to eq 'Newspaper'
    end
    it 'journal has correct format' do
      expect(@journal['format'][0]).to eq 'Journal'
    end
    #it 'dissertation has correct format' do
    #  expect(@dissertation['format'][0]).to eq 'Dissertation or Thesis'
    #end
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
    @rec = trajectify('has_abstract')
    @rec_no_abstract = trajectify('ejournal')
  end

  it 'correctly has the abstract' do
    abstract = @rec['abstract_display'][0]
    expect(abstract).to include 'Martin Luther King'
  end

  it 'correctly does not have an abstract' do
    abstract = @rec_no_abstract['abstract_display']
    expect(abstract).to be_nil
  end

end
