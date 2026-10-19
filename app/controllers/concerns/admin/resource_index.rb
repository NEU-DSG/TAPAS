# Search, search filters, sorting and pagination for admin index pages.
#
# Each controller declares which columns can be searched and sorted, plus any
# named filters typed into the search box as "name:" (e.g. "public:").
module Admin
  module ResourceIndex
    extend ActiveSupport::Concern

    PER_PAGE = 20

    included do
      class_attribute :search_columns, default: []
      class_attribute :sort_columns, default: []
      class_attribute :search_filters, default: {}

      helper_method :search_term, :search_filters, :searchable?, :sort_column, :sort_direction
    end

    class_methods do
      def admin_index(search: [], sort: [], filters: {})
        self.search_columns = search
        self.sort_columns = sort.map(&:to_s)
        self.search_filters = filters
      end
    end

    private

    def index_resources(scope)
      scope = apply_search(scope)
      scope = sort_column ? scope.reorder(sort_column => sort_direction) : scope.order(:id)
      scope.page(params[:page]).per(PER_PAGE)
    end

    def searchable?
      search_columns.any? || search_filters.any?
    end

    def search_term
      params[:search].to_s.strip
    end

    def sort_column
      params[:order] if sort_columns.include?(params[:order])
    end

    def sort_direction
      params[:direction] == "desc" ? :desc : :asc
    end

    def apply_search(scope)
      filter_terms, text_terms = search_term.split.partition { |term| search_filter_for(term) }
      filter_terms.each { |term| scope = search_filter_for(term).call(scope) }

      text = text_terms.join(" ")
      return scope if text.blank? || search_columns.empty?

      pattern = "%#{scope.klass.sanitize_sql_like(text)}%"
      table = scope.klass.arel_table
      scope.where(search_columns.map { |column| table[column].matches(pattern) }.reduce(:or))
    end

    def search_filter_for(term)
      return unless term.end_with?(":")

      search_filters[term.delete_suffix(":").to_sym]
    end
  end
end
