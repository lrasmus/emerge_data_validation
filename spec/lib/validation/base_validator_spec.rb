require 'spec_helper'
require 'validation/base_validator'

describe EMERGE::Phenotype::BaseValidator do
  describe "convert_string_to_number" do
    it "converts an integer" do
      validator = EMERGE::Phenotype::BaseValidator.new(nil, nil)
      validator.convert_string_to_number("100", :integer).should be_a(Integer)
      validator.convert_string_to_number("-05", :integer).should be_a(Integer)
    end

    it "converts a float" do
      validator = EMERGE::Phenotype::BaseValidator.new(nil, nil)
      validator.convert_string_to_number("100", :decimal).should be_a(Float)
      validator.convert_string_to_number("10.0", :decimal).should be_a(Float)
      validator.convert_string_to_number("-10.0", :decimal).should be_a(Float)
    end

    it "defaults to nil for non-numeric types" do
      validator = EMERGE::Phenotype::BaseValidator.new(nil, nil)
      validator.convert_string_to_number("100", :encoded).should be_nil
    end

    it "converts invalid numbers to nil" do
      validator = EMERGE::Phenotype::BaseValidator.new(nil, nil)
      validator.convert_string_to_number("100a", :integer).should be_nil
      validator.convert_string_to_number("12*0", :decimal).should be_nil
      validator.convert_string_to_number("", :decimal).should be_nil
    end
  end
end