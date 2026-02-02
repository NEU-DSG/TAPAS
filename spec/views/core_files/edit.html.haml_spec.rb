require 'rails_helper'

RSpec.describe "core_files/edit", type: :view do
  let(:core_file) {
    create(:core_file, title: "MyString", description: "MyText")
  }

  before(:each) do
    assign(:core_file, core_file)
  end

  it "renders the edit core_file form" do
    render

    assert_select "form[action=?][method=?]", core_file_path(core_file), "post" do
      assert_select "input[name=?]", "core_file[title]"

      assert_select "textarea[name=?]", "core_file[description]"
    end
  end
end
