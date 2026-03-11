# frozen_string_literal: true

class CatalogController < ApplicationController
  include Blacklight::Catalog

  configure_blacklight do |config|
    # Solr connection configuration
    config.connection_config = {
      url: ENV.fetch("SOLR_URL", "http://127.0.0.1:8983/solr/tapas-core")
    }

    # Default parameters for Solr queries
    config.default_solr_params = {
      qt: "search",
      rows: 10,
      "q.alt" => "*:*"
    }

    # Solr path used for search queries
    config.solr_path = "select"
    config.document_solr_path = "get"

    # Unique key for documents in Solr
    config.document_unique_id_param = :id

    # ===================
    # Search Fields
    # ===================
    # Fields that users can search within

    config.add_search_field "all_fields", label: "All Fields" do |field|
      field.include_in_simple_select = true
      field.solr_parameters = {
        qf: "title_info_title_ssi creator_tesim depositor_tesim",
        pf: "title_info_title_ssi^5 creator_tesim^3"
      }
    end

    config.add_search_field("title") do |field|
      field.solr_parameters = {
        qf: "title_info_title_ssi",
        pf: "title_info_title_ssi"
      }
    end

    config.add_search_field("creator") do |field|
      field.solr_parameters = {
        qf: "creator_tesim",
        pf: "creator_tesim"
      }
    end

    # ===================
    # Facet Fields
    # ===================
    # Fields for faceted navigation/filtering

    config.add_facet_field "active_record_model_ssi", label: "Resource Type", limit: 5
    config.add_facet_field "access_ssim", label: "Access", limit: 5
    config.add_facet_field "type_ssim", label: "Content Type", limit: 10
    config.add_facet_field "project_ssim", label: "Project", limit: 10
    config.add_facet_field "collections_ssim", label: "Collections", limit: 10

    # ===================
    # Index Fields
    # ===================
    # Fields to display in search results list

    config.add_index_field "title_info_title_ssi", label: "Title"
    config.add_index_field "creator_tesim", label: "Creator"
    config.add_index_field "active_record_model_ssi", label: "Type"
    config.add_index_field "access_ssim", label: "Access"
    config.add_index_field "type_ssim", label: "Content Type"

    # ===================
    # Show Fields
    # ===================
    # Fields to display on individual record show pages

    config.add_show_field "title_info_title_ssi", label: "Title"
    config.add_show_field "creator_tesim", label: "Creator"
    config.add_show_field "depositor_tesim", label: "Depositor"
    config.add_show_field "active_record_model_ssi", label: "Resource Type"
    config.add_show_field "type_ssim", label: "Content Type"
    config.add_show_field "access_ssim", label: "Access Level"
    config.add_show_field "project_ssim", label: "Project"
    config.add_show_field "collections_ssim", label: "Collections"
    config.add_show_field "edit_access_person_ssim", label: "Editor"
    config.add_show_field "table_id_ssi", label: "Database ID"

    # ===================
    # Sort Options
    # ===================

    config.add_sort_field "score desc, title_info_title_ssi asc", label: "Relevance"
    config.add_sort_field "title_info_title_ssi asc", label: "Title A-Z"
    config.add_sort_field "title_info_title_ssi desc", label: "Title Z-A"

    # ===================
    # Results Configuration
    # ===================

    config.default_per_page = 10
    config.max_per_page = 100
    config.per_page = [ 10, 20, 50, 100 ]

    # Gallery view configuration (blacklight-gallery gem)
    config.view.gallery.partials = [ :index_header ]
    config.view.masonry.partials = [ :index ]
    config.view.slideshow.partials = [ :index ]

    # Default view type
    config.view.list.partials = [ :index_header, :index ]
    config.view.list.icon_class = "fa fa-list"
  end

  # Override index action to redirect to welcome page
  # Frontend will implement the actual search UI later
  def index
    redirect_to root_path
  end

  # Override show action to redirect to welcome page
  # Frontend will implement the actual detail view later
  def show
    redirect_to root_path
  end
end
