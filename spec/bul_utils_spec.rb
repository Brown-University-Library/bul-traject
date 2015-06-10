require 'bul_utils'

describe "bul_utils" do
  it "identifies a suppressed record" do
    rec = read('suppressed.mrc')
    is_sup = suppressed(rec)
    expect(is_sup).to be_truthy
  end

  it "identifies a non-suppressed record" do
    rec = read('named_collection.mrc')
    is_sup = suppressed(rec)
    expect(is_sup).to be_falsey
  end

  it "correctly identifies an online record" do
    rec = read('ejournal.mrc')
    is_online = is_online(rec)
    expect(is_online).to be true
  end

  it "correctly identifies an online record from the bib location" do
    rec = read_marc('online_from_bib_location.json')
    is_online = is_online(rec)
    expect(is_online).to be true
  end

  it "correctly identifies a non-online record" do
    rec = read('book_880.mrc')
    is_online = is_online(rec)
    expect(is_online).to be false
  end

end