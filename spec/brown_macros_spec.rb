require 'traject'

require 'lib/brown_macros'


def read(name)
  path = File.expand_path(File.join("fixtures", name), File.dirname(__FILE__))
  record = MARC::Reader.new(path).to_a.first
  return record
end

describe "BrownMacros" do
  Marc21 = Traject::Macros::Marc21 # shortcut

  before do
    @indexer = Traject::Indexer.new
    @indexer.extend BrownMacros
  end

  describe 'author facet' do
    it "ignores named collection" do
      rec = read('named_collection.mrc')
      @indexer.instance_eval do
        to_field "author_facet", author_facet
      end
      output = @indexer.map_record(rec)
      #Should be only one author for this sample rec.
      expect(output["author_facet"]).to contain_exactly('Silliman, Ronald, 1946-')
    end
  end

end

