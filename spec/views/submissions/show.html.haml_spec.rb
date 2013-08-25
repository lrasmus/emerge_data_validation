require 'spec_helper'

describe "submissions/show" do
  before(:each) do
    @submission = assign(:submission, stub_model(Submission,
      :data_dictionary => "Data Dictionary",
      :data_file => "Data File",
      :content_type => "Content Type",
      :organization => "Organization"
    ))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Data Dictionary/)
    rendered.should match(/Data File/)
    rendered.should match(/Content Type/)
    rendered.should match(/Organization/)
  end
end
