require 'rails_helper'

RSpec.describe "collections/show", type: :view do
  before(:each) do
    assign(:collection, create(:collection, title: "Title", description: "MyText"))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(/Title/)
    expect(rendered).to match(/MyText/)
  end
end
