module SolrHelpers
  extend ActiveSupport::Concern

  SOLR_CORE_URL = ENV.fetch("DEV_SOLR_URL", "http://127.0.0.1:8983/solr/tapas-core")

  def solr_connection
    @solr_connection ||= RSolr.connect(url: SOLR_CORE_URL)
  end

  def self.solr_connection
    @solr_connection ||= RSolr.connect(url: SOLR_CORE_URL)
  end

  # queries the index for records by id if no field_name or field_value are provided
  def locate_record(field_name = nil, field_value = nil)
    record = self.to_solr
    field_name ||= "id"
    field_value ||= record["id"]

    solr_connection.get("select", params: { q: "#{field_name}:#{RSolr.escape(field_value.to_s)}" })["response"]
  end

  def index_record(record = nil)
    record ||= self unless self == "SolrHelpers"

    solr_connection.add(record.to_solr)
    solr_connection.commit
  end

  # Built from class and id rather than to_solr: after a destroy the record's
  # associations can be gone, and to_solr reads them. A Solr outage is logged, not
  # raised, so it cannot undo the database delete; `rails solr:reindex` repairs the index.
  def delete_record
    record_id = "#{self.class}_#{id}"

    solr_connection.delete_by_id(record_id)
    solr_connection.commit
  rescue RSolr::Error::Http, RSolr::Error::ConnectionRefused => e
    Rails.logger.error("Could not remove #{record_id} from Solr: #{e.message}")
  end

  def self.delete_all_indexed_records
    Rails.logger.info("Deleting all Solr indexed records.")

    solr_connection.delete_by_query("*:*")
    solr_connection.commit
  end

  def self.record_count(query = nil)
    query ||= { q: "*:*" }

    solr_connection.get("select", params: query)["response"]["numFound"]
  end
end
