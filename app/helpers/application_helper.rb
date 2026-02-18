module ApplicationHelper
  def title(page_title)
    content_for(:title) { page_title }
    page_title
  end

  def errors_for(object)
    return "" if object.errors.empty?

    content_tag(:div, class: "error_explanation") do
      content_tag(:ul) do
        safe_join(object.errors.full_messages.map { |msg| content_tag(:li, msg) })
      end
    end
  end
end
