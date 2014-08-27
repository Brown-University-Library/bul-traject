require 'traject'
require 'marc'

require 'lib/brown_format'


def read(name)
  path = File.expand_path(File.join("fixtures", name), File.dirname(__FILE__))
  record = MARC::Reader.new(path).first
  return record
end


describe 'newspaper' do
  before do
    @record = read('newspaper.mrc')
    @bruf = BrownFormat.new(@record)
  end

  it "gets the right format code" do
    expect(@bruf.primary).to eq "AN"
  end
end

describe 'video' do
  before do
    @record = read('video.mrc')
    @bruf = BrownFormat.new(@record)
  end

  it "gets the right format code" do
    expect(@bruf.primary).to eq "BV"
  end
end