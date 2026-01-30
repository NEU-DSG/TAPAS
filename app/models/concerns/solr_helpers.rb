module SolrHelpers
  extend ActiveSupport::Concern

  SOLR_CORE_URL = ENV.fetch("DEV_SOLR_URL", "http://127.0.0.1:8983/solr/tapas-core")
  SOLR_CORE_CONNECTION = RSolr.connect(url: SOLR_CORE_URL)

  # queries the index for records by id if no field_name or field_value are provided
  def locate_record(field_name = nil, field_value = nil)
    record = self.to_solr
    field_name ||= "id"
    field_value ||= record["id"]

    SOLR_CORE_CONNECTION.get("select", params: { q: "#{field_name}:#{field_value}" })["response"]
  end

  def index_record(record = nil)
    record ||= self unless self == "SolrHelpers"

    SOLR_CORE_CONNECTION.add(record.to_solr)
    SOLR_CORE_CONNECTION.commit
  end

  def update_record(record = nil)
    record ||= self unless self == "SolrHelpers"

    SOLR_CORE_CONNECTION.update(record.to_solr)
    SOLR_CORE_CONNECTION.commit
  end

  def delete_record
    record_id = self.to_solr["id"]

    SOLR_CORE_CONNECTION.delete_by_id("#{record_id}")
    SOLR_CORE_CONNECTION.commit
  end

  def self.delete_all_indexed_records
    puts "Deleting solr indexed records."

    SOLR_CORE_CONNECTION.delete_by_query("*:*")
    SOLR_CORE_CONNECTION.commit
  end

  def self.record_count(query = nil)
    query ||= { q: "*:*" }

    SOLR_CORE_CONNECTION.get("select", params: query)["response"]["numFound"]
  end
end
