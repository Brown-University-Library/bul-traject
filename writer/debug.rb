require 'traject'
require 'traject/debug_writer'

settings do
  provide "writer_class_name", "Traject::DebugWriter"
  provide "output_file", "debug_output.txt"
  provide 'processing_thread_pool', 3
end

