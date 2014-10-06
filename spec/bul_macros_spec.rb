require 'traject'
require 'marc/record'

require 'lib/bul_macros'


def read(name)
  path = File.expand_path(File.join("fixtures", name), File.dirname(__FILE__))
  record = MARC::Reader.new(path).to_a.first
  return record
end

describe "BulMacros" do
  Marc21 = Traject::Macros::Marc21

  before do
    @indexer = Traject::Indexer.new
    @indexer.extend BulMacros
    @record = read('named_collection.mrc')
  end

  it "identifies the proper record id" do
    @indexer.instance_eval do
      to_field "id", record_id
    end
    output = @indexer.map_record(@record)
    expect(output["id"]).to eq ["b7311191"]
  end

  describe 'author facet' do

    it "ignores named collection" do
      @indexer.instance_eval do
        to_field "author_facet", author_facet
      end
      output = @indexer.map_record(@record)
      #Should be only one author for this sample rec.
      expect(output["author_facet"]).to contain_exactly('Silliman, Ronald, 1946-')
    end

    it "correctly skips an author field that is just a period." do
      @record.append MARC::DataField.new('700', '', ' ', ['a', '.'])
      @indexer.instance_eval do
        to_field "author_facet", author_facet
      end
      output = @indexer.map_record(@record)
      #Should be only one author for this sample rec.
      expect(output["author_facet"]).to contain_exactly('Silliman, Ronald, 1946-')
    end
  end

end

