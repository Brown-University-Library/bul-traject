require 'traject'
require 'marc/marc4j'
require 'traject/marc4j_reader'


settings do
  provide "reader_class_name", "Traject::Marc4JReader"
  provide "marc_source.type", "xml"
end
