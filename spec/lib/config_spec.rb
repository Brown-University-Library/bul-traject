# encoding: UTF-8

require 'json'

describe 'From config.rb' do
  before(:all) do

  def trajectify(fixture_name)
    o = '/tmp/tmp.json'
    i = File.expand_path("../../fixtures/#{fixture_name}.mrc",__FILE__)
    c = File.expand_path('../../../bul_index.rb',__FILE__)
    system "traject -c #{c} #{i} -w Traject::JsonWriter -o #{o}"
    JSON.parse(IO.read(o))
  end
  @book_880 = trajectify('book_880')
  @newspaper = trajectify('newspaper')
  @journal = trajectify('journal')
  @dissertation = trajectify('dissertation')

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