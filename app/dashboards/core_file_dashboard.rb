require "administrate/base_dashboard"

class CoreFileDashboard < Administrate::BaseDashboard
  # ATTRIBUTE_TYPES
  # a hash that describes the type of each of the model's fields.
  #
  # Each different type represents an Administrate::Field object,
  # which determines how the attribute is displayed
  # on pages throughout the dashboard.
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    collection_core_files: Field::HasMany,
    collections: Field::HasMany,
    depositor: Field::BelongsTo,
    description: Field::Text,
    image_file: Field::HasOne,
    is_public: Field::Boolean,
    ography_type: Field::String,
    tei_authors: Field::Text,
    tei_contributors: Field::Text,
    title: Field::String,
    created_at: Field::DateTime,
    updated_at: Field::DateTime,
  }.freeze

  # COLLECTION_ATTRIBUTES
  # an array of attributes that will be displayed on the model's index page.
  #
  # By default, it's limited to four items to reduce clutter on index pages.
  # Feel free to add, remove, or rearrange items.
  COLLECTION_ATTRIBUTES = %i[
    title
    depositor
    ography_type
    is_public
    created_at
  ].freeze

  # SHOW_PAGE_ATTRIBUTES
  # an array of attributes that will be displayed on the model's show page.
  SHOW_PAGE_ATTRIBUTES = %i[
    id
    title
    description
    depositor
    collections
    ography_type
    tei_authors
    tei_contributors
    is_public
    image_file
    created_at
    updated_at
  ].freeze

  # FORM_ATTRIBUTES
  # an array of attributes that will be displayed
  # on the model's form (`new` and `edit`) pages.
  FORM_ATTRIBUTES = %i[
    title
    description
    depositor
    collections
    ography_type
    is_public
  ].freeze

  # COLLECTION_FILTERS
  # a hash that defines filters that can be used while searching via the search
  # field of the dashboard.
  #
  # For example to add an option to search for open resources by typing "open:"
  # in the search field:
  #
  #   COLLECTION_FILTERS = {
  #     open: ->(resources) { resources.where(open: true) }
  #   }.freeze
  COLLECTION_FILTERS = {
    public: ->(resources) { resources.where(is_public: true) },
    private: ->(resources) { resources.where(is_public: false) },
    ography: ->(resources) { resources.where.not(ography_type: nil) },
  }.freeze

  # Overwrite this method to customize how core files are displayed
  # across all pages of the admin dashboard.
  def display_resource(core_file)
    core_file.title
  end
end
