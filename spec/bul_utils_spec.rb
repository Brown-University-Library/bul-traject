require 'lib/bul_utils'

describe "bul_utils" do
  it "identifies a suppressed record" do
    rec = read('suppressed.mrc')
    is_sup = suppressed(rec)
    expect(is_sup).to be_truthy
  end

  it "identifies a suppressed record" do
    rec = read('suppressed.mrc')
    @indexer.instance_eval do
      to_field "hide", suppressed
    end
    output = @indexer.map_record(rec)
    expect(output["hide"]).to eq [true]
  end
end