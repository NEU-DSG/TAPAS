# View helpers for admin pages. Prefixed with admin_ because Rails mixes every
# helper into every view, public pages included.
module Admin
  module ApplicationHelper
    def admin_display_name(record)
      case record
      when User then record.email
      when ImageFile then record.title.presence || "ImageFile ##{record.id}"
      else
        (record.try(:title).presence if record.respond_to?(:title)) ||
          "#{record.model_name.human} ##{record.id}"
      end
    end

    # Renders one attribute for an index cell or show page: associations as
    # links to their admin pages, everything else as plain text.
    def admin_value(record, attribute)
      value = record.public_send(attribute)

      case value
      when ActiveRecord::Base then admin_record_link(value)
      when ActiveRecord::Relation, Array then safe_join(value.map { |item| admin_record_link(item) }, ", ")
      when ActiveSupport::TimeWithZone, Time, DateTime then l(value, format: :long)
      when true, false then value.to_s
      else value.to_s
      end
    end

    def admin_record_link(record)
      path_helper = "admin_#{record.model_name.singular_route_key}_path"
      return admin_display_name(record) unless respond_to?(path_helper)

      link_to admin_display_name(record), public_send(path_helper, record)
    end

    # Column header that toggles ascending/descending sort, keeping the current
    # search term. Every sortable header carries an arrow so it reads as
    # clickable; the sorted column's arrow shows the direction.
    def admin_sort_link(attribute, label = nil)
      column = attribute.to_s
      label ||= column.humanize
      current = sort_column == column
      direction = current && sort_direction == :asc ? "desc" : "asc"
      arrow = if current
        sort_direction == :asc ? "▲" : "▼"
      else
        "↕"
      end

      link_to request.query_parameters.merge("order" => column, "direction" => direction, "page" => nil).compact,
              class: class_names("sort-link", "sort-link--active": current), title: "Sort by #{label}" do
        safe_join([ label, tag.span(arrow, class: "sort-link__arrow", aria: { hidden: true }) ], " ")
      end
    end

    # Toggle button for a search filter: adds or removes its "name:" keyword in
    # the search box, keeping the rest of the search and the sort.
    def admin_filter_link(name)
      keyword = "#{name}:"
      terms = search_term.split
      active = terms.include?(keyword)
      terms = active ? terms - [ keyword ] : terms + [ keyword ]

      link_to name.to_s.humanize,
              request.query_parameters.merge("search" => terms.join(" ").presence, "page" => nil).compact,
              class: class_names("filter-btn", active: active),
              title: active ? "Remove the #{keyword} filter" : "Show only matches for #{keyword}"
    end

    def admin_aria_sort(attribute)
      return unless sort_column == attribute.to_s

      sort_direction == :asc ? "ascending" : "descending"
    end
  end
end
