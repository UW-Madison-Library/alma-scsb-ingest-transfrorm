class Transformer

  def initialize(configuration)
    @configuration = configuration
    @enrichment_fields = @configuration.reduce(Array.new) do |fields, (key, entry)|
      fields << entry[:field] if entry.is_a?(Hash) && entry[:field]
      fields
    end
  end


  def to_ingest_document(record)
    builder = Nokogiri::XML::Builder.new do |document|
      document.bibRecord do
        document.bib do |bib|
          bib.owningInstitutionId(@configuration[:institution_code])
          bib.content do
            bib.collection(xmlns: "http://www.loc.gov/MARC21/slim") do |marc|
              marc.parent << Nokogiri::XML(self.bib_without_enhancements(record).to_xml.to_s).at("record")
            end
          end # bibRecord/bib/content
        end # bibRecord/bib

        document.holdings do
          record.fields(@configuration[:locations][:field]).each do |location|
            holding_statements = record.fields(@configuration[:summary_statements][:field]).select {|s| s["8"] == location["8"]}
            document.holding do |holding|
              holding.owningInstitutionHoldingsId(location["8"])
              holding.content do
                holding.collection(xmlns: "http://www.loc.gov/MARC21/slim") do |marc|
                  marc.record do
                    marc.datafield(tag: "852", ind1: location.indicator1, ind2: location.indicator2) do
                      @configuration[:locations][:subfields].each do |sf_code|
                        marc.subfield(location[sf_code], code: sf_code) if location[sf_code]
                      end
                    end # bibRecord/holdings/holding/content/collection/record/datafield[tag="852"]

                    holding_statements.each do |stmt|
                      marc.datafield(tag: "866", ind1: stmt.indicator1, ind2: stmt.indicator2) do
                        @configuration[:summary_statements][:subfields].each do |sf_code|
                          marc.subfield(stmt[sf_code], code: sf_code) if stmt[sf_code]
                        end
                      end # holding_statements.each
                    end # bibRecord/holdings/holding/content/collection/record/datafield[tag="866"]
                  end # bibRecord/holdings/holding/content/collection/record
                end # bibRecord/holdings/holding/content/collection
              end # bibRecord/holdings/holding/content

              document.items do
                holding_items = record.fields(@configuration[:item_enrichment][:field]).select {|i| i["0"] == location["8"]}
                document.content do |items|
                  items.collection(xmlns: "http://www.loc.gov/MARC21/slim") do |marc|
                    holding_items.each do |item|
                      marc.record do
                        marc.datafield(tag: "876", ind1: location.indicator1, ind2: location.indicator2) do
                          marc.subfield(item[@configuration[:item_enrichment][:pid_sf]], code: "a") if item[@configuration[:item_enrichment][:pid_sf]]
                          marc.subfield(item[@configuration[:item_enrichment][:barcode_sf]], code: "p") if item[@configuration[:item_enrichment][:barcode_sf]]
                          marc.subfield(item[@configuration[:item_enrichment][:copy_id_sf]], code: "t") if item[@configuration[:item_enrichment][:copy_id_sf]]
                          marc.subfield(item[@configuration[:item_enrichment][:status_sf]], code: "j") if item[@configuration[:item_enrichment][:status_sf]]
                          marc.subfield(item[@configuration[:item_enrichment][:description_sf]], code: "3") if item[@configuration[:item_enrichment][:description_sf]]
                          marc.subfield(item[@configuration[:item_enrichment][:process_type_sf]], code: "x") if item[@configuration[:item_enrichment][:process_type_sf]]
                          marc.subfield(item[@configuration[:item_enrichment][:create_date_sf]], code: "d") if item[@configuration[:item_enrichment][:create_date_sf]]
                          marc.subfield(item[@configuration[:item_enrichment][:commitment_sf]], code: "r") if item[@configuration[:item_enrichment][:commitment_sf]]
                          marc.subfield(item[@configuration[:item_enrichment][:retention_reason_sf]], code: "s") if item[@configuration[:item_enrichment][:retention_reason_sf]]
                        end # bibRecord/holdings/holding/content/items/content/collection/record/datafield[tag="876"]
                      end # bibRecord/holdings/holding/content/items/content/collection/record
                    end # holding_items.each
                  end # bibRecord/holdings/holding/content/items/content/collection
                end # bibRecord/holdings/holding/content/items/content
              end # bibRecord/holdings/holding/content/items
            end # bibRecord/holdings/holding
          end # @locations.each
        end # bibRecord/holdings
      end # bibRecord
    end # builder

    builder.doc
  end


  private


  def bib_without_enhancements(record)
    cloned_rec = MARC::Record.new
    cloned_rec.leader = record.leader
    record.fields.each do |field|
      cloned_rec << field unless @enrichment_fields.include?(field.tag)
    end
    cloned_rec
  end

end
