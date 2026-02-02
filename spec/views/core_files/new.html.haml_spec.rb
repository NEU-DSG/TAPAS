require 'rails_helper'

RSpec.describe "core_files/new", type: :view do
  before(:each) do
    assign(:core_file, CoreFile.new(
      title: "MyString",
      description: "MyText"
    ))
  end

  it "renders new core_file form" do
    render

    assert_select "form[action=?][method=?]", core_files_path, "post" do
      assert_select "input[name=?]", "core_file[title]"

      assert_select "textarea[name=?]", "core_file[description]"
    end
  end
end
