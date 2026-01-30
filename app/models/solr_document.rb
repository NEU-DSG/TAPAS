# frozen_string_literal: true

class SolrDocument
  include Blacklight::Solr::Document

  self.unique_key = "id"

  use_extension(Blacklight::Document::DublinCore)

  attribute :klass_type, Blacklight::Types::String, "active_record_model_ssi"

  def klass
    klass_type.constantize if klass_type.present?
  end

  def record_type
    Array(self["active_record_model_ssi"]).first
  end
end
