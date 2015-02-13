require 'traject'
require 'marc/record'

require 'traject/macros/marc21_semantics'
require 'bul_macros'

extend  Traject::Macros::Marc21Semantics


def read(name)
  path = File.expand_path(File.join("fixtures", name), File.dirname(__FILE__))
  record = MARC::Reader.new(path).to_a.first
  return record
end

describe "BulMacros" do
  Marc21 = Traject::Macros::Marc21
  Marc21Semantics = Traject::Macros::Marc21Semantics

  before do
    @indexer = Traject::Indexer.new
    @indexer.extend BulMacros
    @indexer.extend Marc21Semantics
    @record = read('named_collection.mrc')
  end

  it "identifies the proper record id" do
    @indexer.instance_eval do
      to_field "id", record_id
    end
    output = @indexer.map_record(@record)
    expect(output["id"]).to eq ["b7311191"]
  end

  it "correctly identifies the last update date" do
    @indexer.instance_eval do
      to_field "updated_dt", updated_date
    end
    rec = read('book_880.mrc')
    output = @indexer.map_record(rec)
    expect(output['updated_dt'][0].to_s).to eq "2013-04-30T00:00:00Z"
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

  it "correctly identifies an OCLC number in 001" do
    @indexer.instance_eval do
      to_field "oclc_t", oclcnum('001:035a:035z')
    end
    rec = read('ejournal.mrc')
    output = @indexer.map_record(rec)
    expect(output["oclc_t"]).to contain_exactly('49896747')
  end

  it "correctly identifies an OCLC number in 001 and ignores value in 035" do
    @indexer.instance_eval do
      to_field "oclc_t", oclcnum('001:035a:035z')
    end
    rec = read('journal_multiple_items.mrc')
    output = @indexer.map_record(rec)
    expect(output["oclc_t"]).to contain_exactly('03904985')
  end

end

