require 'traject'
require 'traject/json_writer'

settings do
  provide "writer_class_name", "Traject::JsonWriter"
  provide "output_file", "out.json"
  provide 'processing_thread_pool', 3
end

