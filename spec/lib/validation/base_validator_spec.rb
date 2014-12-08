require 'spec_helper'
require 'validation/base_validator'

describe EMERGE::Phenotype::BaseValidator do
  before :each do
    @validator = EMERGE::Phenotype::BaseValidator.new(nil, nil)
  end

  describe "convert_string_to_number" do
    it "converts an integer" do
      expect(@validator.convert_string_to_number("100", :integer)).to be_a(Integer)
      expect(@validator.convert_string_to_number("-05", :integer)).to be_a(Integer)
    end

    it "converts a float" do
      expect(@validator.convert_string_to_number("100", :decimal)).to be_a(Float)
      expect(@validator.convert_string_to_number("10.0", :decimal)).to be_a(Float)
      expect(@validator.convert_string_to_number("-10.0", :decimal)).to be_a(Float)
    end

    it "defaults to nil for non-numeric types" do
      expect(@validator.convert_string_to_number("100", :encoded)).to be_nil
    end

    it "converts invalid numbers to nil" do
      expect(@validator.convert_string_to_number("100a", :integer)).to be_nil
      expect(@validator.convert_string_to_number("12*0", :decimal)).to be_nil
      expect(@validator.convert_string_to_number("", :decimal)).to be_nil
    end
  end

  describe "adds messages to collections" do
    it "adds an error" do
      @validator.add_row_error(1, "Test message new 1")
      @validator.add_row_error(2, "Test message new 2")
      @validator.add_row_error(1, "Test message other 1")
      expect(@validator.results.length).to eql 2
      expect(@validator.results[:errors][:rows][1].length).to eql 2
      expect(@validator.results[:errors][:rows][2].length).to eql 1
      expect(@validator.results[:errors][:rows][3]).to be_nil
    end

    it "adds a warning" do
      @validator.add_row_warning(1, "Test message new 1")
      @validator.add_row_warning(2, "Test message new 2")
      @validator.add_row_warning(1, "Test message other 1")
      expect(@validator.results.length).to eql 2
      expect(@validator.results[:warnings][:rows][1].length).to eql 2
      expect(@validator.results[:warnings][:rows][2].length).to eql 1
      expect(@validator.results[:warnings][:rows][3]).to be_nil
    end
  end

  describe "at_result_collection_limit" do
    it "returns false if no limit is specified" do
      @validator.add_row_error(1, "Test message")
      @validator.add_row_error(2, "Test message")
      expect(@validator.at_result_collection_limit?(:errors, :rows)).to be false
    end

    it "always returns true if a negative limit is specified" do
      @validator = EMERGE::Phenotype::BaseValidator.new(nil, nil, :csv, -1)
      expect(@validator.at_result_collection_limit?(:errors, :rows)).to be true
    end

    it "responds when limit reached" do
      @validator = EMERGE::Phenotype::BaseValidator.new(nil, nil, :csv, 2)
      @validator.add_row_error(1, "Test message")
      expect(@validator.at_result_collection_limit?(:errors, :rows)).to be false
      @validator.add_row_error(2, "Test message")
      expect(@validator.at_result_collection_limit?(:errors, :rows)).to be true
    end

    it "doesn't count multiple errors against a single row" do
      @validator = EMERGE::Phenotype::BaseValidator.new(nil, nil, :csv, 2)
      @validator.add_row_error(1, "Test message")
      @validator.add_row_error(1, "Test message")
      expect(@validator.at_result_collection_limit?(:errors, :rows)).to be false
    end
  end
end