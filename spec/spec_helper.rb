require 'json'
require 'marc'

RSpec.configure do |config|
end



def read_marc(name)
  path = File.expand_path(File.join("fixtures", name), File.dirname(__FILE__))
  if path.end_with? "json"
    json_file = File.read(path)
    record = MARC::Record.new_from_hash( JSON.parse( json_file ) )
  else
    record = MARC::Reader.new(path).to_a.first
  end
  return record
end
