require 'rails_helper'

RSpec.describe "welcome/index.html.haml", type: :view do
  it "renders the welcome page" do
    render
    expect(rendered).to include("Welcome to TAPAS")
  end
end
