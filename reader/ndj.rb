require 'traject'
require 'traject/marc_reader'
require 'traject/ndj_reader'


settings do
  provide "reader_class_name", "Traject::NDJReader"
  provide "marc_source.type", "ndj"
end