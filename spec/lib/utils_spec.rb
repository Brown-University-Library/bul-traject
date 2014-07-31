require 'traject'
require 'marc'

require 'lib/utils'

def fpath(name)
  File.expand_path("../../fixtures/#{name}.mrc",__FILE__)
end

describe 'From lib/utils.rb' do
  before do
    @record = MARC::Reader.new(fpath 'suppressed').first
    @record2 = MARC::Reader.new(fpath 'newspaper').first
  end

  it "correctly identifies a suppressed record" do
    is_s = suppressed(@record)
    expect(is_s).to be true
  end

  it "correctly identifies a non-suppressed record" do
    is_s = suppressed(@record2)
    expect(is_s).to be false
  end

end