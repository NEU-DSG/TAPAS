require 'rails_helper'

RSpec.describe "collections/index", type: :view do
  before(:each) do
    assign(:collections, [
      create(:collection, title: "Title", description: "MyText"),
      create(:collection, title: "Title", description: "MyText")
    ])
  end

  it "renders a list of collections" do
    render
    cell_selector = 'td'
    assert_select cell_selector, text: Regexp.new("Title".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("MyText".to_s), count: 2
  end
end
