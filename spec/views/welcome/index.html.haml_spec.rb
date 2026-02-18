require 'rails_helper'

RSpec.describe "welcome/index.html.haml", type: :view do
  before do
    allow(view).to receive(:user_signed_in?).and_return(false)
  end

  it "renders the welcome page" do
    render
    expect(rendered).to include("Welcome to TAPAS")
  end
end
