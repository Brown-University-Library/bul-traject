#
# ==============================================================
# NOTE: As of 2018 this is not used anymore.
# We now detect deleted/suppressed records via the Sierra API.
# ==============================================================
#
# Processes a line delimited file where each line contains the JSON
# representation of a Solr document ID to delete. The file to process
# is produced via Traject with the `config_delete.rb` configurationn.
# Each line on the file to process looks as follows:
#
# {"id":["b3187374"]}
# {"id":["b3397561"]}
#
# Syntax:
# SOLR_ENV=http://servername/solrcore ruby process_delete.rb file_name.json
#
require "json"
require "net/http"
# require "byebug"

class Processor
  def initialize(file_name, solr_url, debug_mode)
    @file_name = file_name
    @solr_url = solr_url
    @debug_mode = debug_mode
    if @debug_mode
      @MockResponse = Struct.new(:code)
    end
  end

  def http_get(url)
    if @debug_mode
      log_msg("HTTP GET #{url}")
      return @MockResponse.new("200")
    end
    uri = URI.parse(url)
    http = Net::HTTP.new(uri.host, uri.port)
    if url.start_with?("https://")
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    end
    request = Net::HTTP::Get.new(uri.request_uri)
    response = http.request(request)
  end

  def http_post(url, payload)
    if @debug_mode
      log_msg("HTTP POST #{url} with #{payload}")
      return @MockResponse.new("200")
    end
    uri = URI.parse(url)
    http = Net::HTTP.new(uri.host, uri.port)
    if url.start_with?("https://")
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    end
    request = Net::HTTP::Post.new(uri.request_uri)
    request.add_field("Content-Type", "text/xml")
    request.add_field("Accept", "application/json")
    request.body = payload
    response = http.request(request)
  end

  def delete_from_solr(id)
    url = "#{@solr_url}/update"
    payload = "<delete><query>id:#{id}</query></delete>"
    response = http_post(url, payload)
    if response.code == "200"
      log_msg("Deleted #{id} OK")
    else
      log_warn("Solr returned HTTP #{response.code} for #{id}")
    end
  end

  def commit_solr()
    url = "#{@solr_url}/update?commit=true"
    response = http_get(url)
    if response.code == "200"
      log_msg("Committed changes to Solr OK")
    else
      log_warn("Solr returned HTTP #{response.code} when committing changes")
    end
  end

  def is_valid_id?(id)
    return false if id == nil
    return id[0] == "b" && id.length == 8
  end

  def log_msg(msg)
    puts "#{Time.now} INFO: #{msg}"
  end

  def log_warn(msg)
    puts "#{Time.now} WARN: #{msg}"
  end

  def process_file()
    count = 0
    deleted = 0
    log_msg("Processing: #{@file_name}, Solr: #{@solr_url}")

    File.readlines(@file_name).each do |line|
      count += 1
      json = JSON.parse(line)
      id = (json["id"] || []).first
      if is_valid_id?(id)
        delete_from_solr(id)
        deleted += 1
      else
        log_warn("Skipped line #{count}, id: #{id}.")
      end
    end

    if deleted > 0
      commit_solr()
    end

    log_msg("Done processing #{@file_name}. Deleted #{deleted} out of #{count}.")
  end
end


if ARGV.count != 1
  abort("No JSON file with IDs to delete was received")
end

if ENV["SOLR_URL"] == nil
  abort("No SOLR_URL was found on the environment")
end

debug_only = true
p = Processor.new(ARGV[0], ENV["SOLR_URL"], debug_only)
p.process_file()
