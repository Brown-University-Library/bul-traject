#
# Test formats.  ToDo - remove so much boilerplate.
#

require 'marc'
require 'bul_format'


def get_format(rec_name)
  rec = read_marc(rec_name)
  return Format.new(rec)
end

describe 'Format archive manuscript' do
  am = get_format('archive_manuscript.mrc')
  it "gets the right primary format" do
    expect(am.code).to eq "BAM"
  end
end

describe 'Format book' do
  bk = get_format('book_880.mrc')
  it "gets the right primary format" do
    expect(bk.code).to eq "BK"
  end
end

describe 'Identify dissertations' do

  it "does not identify a non-Brown dissertation" do
    fmt = get_format('non_brown_dissertation.mrc')
    expect(fmt.code).to eq "BK"
  end

  it "correctly identifies a brown dissertation" do
    fmt = get_format('brown_dissertation.mrc')
    expect(fmt.code).to eq "BTD"
  end

  it "correctly identifies a brown dissertation from 502c" do
    fmt = get_format('brown_dissertation_502c.json')
    expect(fmt.code).to eq "BTD"
  end
end

describe 'Identify format periodical titles' do

  it "identifies a journal" do
    fmt = get_format('journal.mrc')
    expect(fmt.code).to eq "BP"
  end

  it "identifies a newspaper" do
    fmt = get_format('newspaper.mrc')
    expect(fmt.code).to eq "BP"
  end

  it "identifies an ejournal" do
    fmt = get_format('ejournal.mrc')
    expect(fmt.code).to eq "BP"
  end

  it "identifies a sersol ejournal" do
    fmt = get_format('sersol_ejournal.mrc')
    expect(fmt.code).to eq "BP"
  end

end

describe 'Format video' do

  it "gets the right primary format for a sciences language dvd" do
    fmt = get_format('sci_lang_dvd.mrc')
    expect(fmt.code).to eq "BV"
  end

  it "gets the right primary format for video without a location code" do
    fmt = get_format('video.mrc')
    expect(fmt.code).to eq "BV"
  end

  it "looks at all 007s to determine format" do
    fmt = get_format('video_multiple007s.mrc')
    expect(fmt.code).to eq "BV"
  end

  it "gets the right format from blevel i" do
    fmt = get_format('was_unknown_blevel_i.json')
    expect(fmt.code).to eq "BV"
  end

end

describe 'Format score' do
  it "gets the right primary format" do
    fmt = get_format('score.mrc')
    expect(fmt.code).to eq "MS"
  end
end

describe 'Format sound recording' do
  it "gets the right primary format" do
    fmt = get_format('interview.mrc')
    expect(fmt.code).to eq "BSR"
  end
end

describe '3D object' do
  it "gets the right format" do
    fmt = get_format('3d_object.mrc')
    expect(fmt.code).to eq "B3D"
  end
end

describe 'Computer file' do
  it "gets the right format" do
    fmt = get_format('computer_file.mrc')
    expect(fmt.code).to eq "CF"
  end
end


describe 'Identify JCB items' do

  it "identifies a level type a and level p as book" do
    #These were previously "unknopwn"
    fmt = get_format('jcb_type_a_level_b.json')
    expect(fmt.code).to eq "BK"
  end

end