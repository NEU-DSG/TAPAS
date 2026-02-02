require 'rails_helper'

RSpec.describe "core_files/index", type: :view do
  before(:each) do
    assign(:core_files, [
      create(:core_file, title: "Title", description: "MyText"),
      create(:core_file, title: "Title", description: "MyText")
    ])
  end

  it "renders a list of core_files" do
    render
    cell_selector = 'td'
    assert_select cell_selector, text: Regexp.new("Title".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("MyText".to_s), count: 2
  end
end
