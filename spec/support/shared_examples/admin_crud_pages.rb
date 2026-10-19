# frozen_string_literal: true

# Index, show, edit, update and destroy for an admin resource page.
#
# Expects these lets from the including spec:
# - resource:       a persisted record
# - index_path, show_path, edit_path
# - index_text:     text the index page shows for the record
# - show_text:      text the show page shows for the record
# - param_key:      the form's param key (e.g. :collection)
# - valid_update:   attributes that should save
# - updated:        a lambda returning true once valid_update has been applied
# - invalid_update: attributes that should fail validation, or nil to skip
RSpec.shared_examples "admin CRUD pages" do
  it "lists the record" do
    resource
    get index_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include(ERB::Util.html_escape(index_text))
  end

  it "shows the record" do
    get show_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include(ERB::Util.html_escape(show_text))
  end

  it "renders the edit form" do
    get edit_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to match(/<form[^>]*class="[^"]*\bform\b/)
  end

  it "updates the record" do
    patch show_path, params: { param_key => valid_update }
    expect(response).to redirect_to(show_path)
    expect(updated.call).to be true
  end

  it "re-renders the form when the update is invalid" do
    skip "no invalid update for this resource" if invalid_update.nil?

    patch show_path, params: { param_key => invalid_update }
    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("error_explanation")
  end

  it "destroys the record" do
    delete show_path
    expect(response).to redirect_to(index_path)
    expect(resource.class.exists?(resource.id)).to be false
  end
end
