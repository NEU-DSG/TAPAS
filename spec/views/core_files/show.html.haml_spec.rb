require 'rails_helper'

RSpec.describe "core_files/show", type: :view do
  before(:each) do
    assign(:core_file, create(:core_file, title: "Title", description: "MyText"))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(/Title/)
    expect(rendered).to match(/MyText/)
  end
end
