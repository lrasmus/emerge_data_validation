require 'spec_helper'

describe "submissions/new" do
  before(:each) do
    assign(:submission, stub_model(Submission,
      :data_dictionary => "MyString",
      :data_file => "MyString",
      :content_type => "MyString",
      :organization => "MyString"
    ).as_new_record)
  end

  it "renders new submission form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form[action=?][method=?]", submissions_path, "post" do
      assert_select "input#submission_data_dictionary[name=?]", "submission[data_dictionary]"
      assert_select "input#submission_data_file[name=?]", "submission[data_file]"
      assert_select "input#submission_content_type[name=?]", "submission[content_type]"
      assert_select "input#submission_organization[name=?]", "submission[organization]"
    end
  end
end
