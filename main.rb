require "fileutils"
require "pathname"
require "yaml"
require "nokogiri"
require "marc"

require_relative "transformer"


start = Time.now
puts "Started"
puts


if ARGV.size > 0
  args = ARGV.map {|argument| argument.split("=")}.to_h
  record_limit = args["--record-limit"].to_i
end


configuration = YAML.load(File.read( Pathname.new(__FILE__).expand_path.dirname.join("transform.yml") ))
data_dir      = Pathname.new(configuration[:data_directory])
input_files   = data_dir.join("alma-published-data").glob("*.xml")
output_dir    = data_dir.join("scsb-ingest-xml")

transformer  = Transformer.new(configuration)
record_count = 0


input_files.sort.each do |input_filepath|
  puts input_filepath

  output_filepath = output_dir.join(input_filepath.basename(input_filepath.extname).to_s + "-scsb-ingest.xml")

  File.open(output_filepath, "w+") do |output_file|
    document      = Nokogiri::XML::Document.new
    bib_records   = Nokogiri::XML::Node.new("bibRecords", document)
    document.root = bib_records

    # Note that Alma Publishing Profile data does not include the MARC/XML namespace
    MARC::XMLReader.new(input_filepath.to_s, parser: "nokogiri", ignore_namespace: true).each do |record|
      record_count += 1
      bib_records.add_child( transformer.to_ingest_document(record).at("bibRecord") )
      break if record_limit && record_count >= record_limit
    end

    output_file.write(document.to_xml)
  end
  break if record_limit && record_count >= record_limit
end
puts "Record Count: #{record_count}"


finish = Time.now
puts
puts start
puts finish
puts finish - start
puts
