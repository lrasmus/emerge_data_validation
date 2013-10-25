require 'spec_helper'
require 'validation/base_validator'

describe EMERGE::Phenotype::BaseValidator do
  before :each do
    @validator = EMERGE::Phenotype::BaseValidator.new(nil, nil)
  end

  describe "convert_string_to_number" do
    it "converts an integer" do
      @validator.convert_string_to_number("100", :integer).should be_a(Integer)
      @validator.convert_string_to_number("-05", :integer).should be_a(Integer)
    end

    it "converts a float" do
      @validator.convert_string_to_number("100", :decimal).should be_a(Float)
      @validator.convert_string_to_number("10.0", :decimal).should be_a(Float)
      @validator.convert_string_to_number("-10.0", :decimal).should be_a(Float)
    end

    it "defaults to nil for non-numeric types" do
      @validator.convert_string_to_number("100", :encoded).should be_nil
    end

    it "converts invalid numbers to nil" do
      @validator.convert_string_to_number("100a", :integer).should be_nil
      @validator.convert_string_to_number("12*0", :decimal).should be_nil
      @validator.convert_string_to_number("", :decimal).should be_nil
    end
  end

  describe "adds messages to collections" do
    it "adds an error" do
      @validator.add_row_error(1, "Test message new 1")
      @validator.add_row_error(2, "Test message new 2")
      @validator.add_row_error(1, "Test message other 1")
      @validator.results.length.should eql 2
      @validator.results[:errors][:rows][1].length.should eql 2
      @validator.results[:errors][:rows][2].length.should eql 1
      @validator.results[:errors][:rows][3].should be_nil
    end

    it "adds a warning" do
      @validator.add_row_warning(1, "Test message new 1")
      @validator.add_row_warning(2, "Test message new 2")
      @validator.add_row_warning(1, "Test message other 1")
      @validator.results.length.should eql 2
      @validator.results[:warnings][:rows][1].length.should eql 2
      @validator.results[:warnings][:rows][2].length.should eql 1
      @validator.results[:warnings][:rows][3].should be_nil
    end
  end
end