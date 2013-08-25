require 'spec_helper'

describe "submissions/index" do
  before(:each) do
    assign(:submissions, [
      stub_model(Submission,
        :data_dictionary => "Data Dictionary",
        :data_file => "Data File",
        :content_type => "Content Type",
        :organization => "Organization"
      ),
      stub_model(Submission,
        :data_dictionary => "Data Dictionary",
        :data_file => "Data File",
        :content_type => "Content Type",
        :organization => "Organization"
      )
    ])
  end

  it "renders a list of submissions" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Data Dictionary".to_s, :count => 2
    assert_select "tr>td", :text => "Data File".to_s, :count => 2
    assert_select "tr>td", :text => "Content Type".to_s, :count => 2
    assert_select "tr>td", :text => "Organization".to_s, :count => 2
  end
end
