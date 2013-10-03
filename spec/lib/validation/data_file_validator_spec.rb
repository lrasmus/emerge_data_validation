require 'spec_helper'
require 'validation/data_file_validator'

describe EMERGE::Phenotype::DataFileValidator do
  VARIABLES = {
    "SUBJID" => {:values => nil, :row => 1, :original_name => "SUBJID", :normalized_type => :string},
    "DIAGNOSIS" => {:values => nil, :row => 2, :original_name => "Diagnosis", :normalized_type => :string}
  }

  it "flags in error a file with only one row" do
    process_with_expected_error("SUBJID,Diagnosis\r\n", "No rows containing data could be found", VARIABLES)
  end

  it "flags in error a file with a blank column" do
    process_with_expected_error("SUBJID,
1,109.8
2,003.3", "The 2nd column has a blank header - please set the header and define it in the data dictionary.", VARIABLES)
  end

  it "flags in warning a file with a blank line (delimiters only)" do
    process_with_expected_warning("SUBJID,Diagnosis
1,109.8
,
2,003.3", "Row 2 appears to be blank and should be removed.", VARIABLES)
  end

  it "flags in error a file where not all columns are used" do
    variables = VARIABLES.clone
    variables["NEW_COL"] = {:values => nil, :row => 3, :original_name => "New_Col", :normailzed_type => :string}
    process_with_expected_error("SUBJID,Diagnosis
1,109.8
2,003.3", "The variable 'New_Col' is defined in the data dictionary, but does not appear in the data file.", variables)
  end

  it "flags in warning columns that are not in the same order as the data dictionary" do
    process_with_expected_warning("Diagnosis,SUBJID\r\n1,109.8\r\n2,003.3",
      "The variable 'Diagnosis' (1st column) is the 2nd variable in the data dictionary.  It's recommended to have variables in the same order.",
      VARIABLES)
  end

  it "flags in error columns that are not in the data dictionary" do
    process_with_expected_error("SUBJID,Diagnosis,Test\r\n1,109.8,1\r\n2,003.3,1",
      "The variable 'Test' (3rd column) is not defined in the data dictionary.",
      VARIABLES)
  end

  it "flags in error empty/blank fields in data rows" do
    process_with_expected_error("SUBJID,Diagnosis\r\n1,  \r\n2,003.3",
      "A value for 'Diagnosis' (1st row) is blank, however it is best practice to provide a value to explicitly define missing data.",
      VARIABLES)
  end

  it "flags in error numeric fields out of range" do
    variables = VARIABLES.clone
    variables["DIAGNOSIS"][:normalized_type] = :integer
    variables["DIAGNOSIS"][:min_value] = 6
    variables["DIAGNOSIS"][:max_value] = 100
    process_with_expected_error("SUBJID,Diagnosis\r\n1,5",
      "The value '5' for 'Diagnosis' (1st row) is outside of the range defined in the data dictionary (6 to 100).",
      variables)

    process_with_expected_success("SUBJID,Diagnosis\r\n1,10", variables)
  end

  it "skips checking numeric fields if min and max aren't specified" do
    variables = VARIABLES.clone
    variables["DIAGNOSIS"][:normalized_type] = :integer
    variables["DIAGNOSIS"][:min_value] = nil
    variables["DIAGNOSIS"][:max_value] = 100
    process_with_expected_success("SUBJID,Diagnosis\r\n1,10", variables)
    variables["DIAGNOSIS"][:min_value] = nil
    variables["DIAGNOSIS"][:max_value] = nil
    process_with_expected_success("SUBJID,Diagnosis\r\n1,10", variables)
  end

  it "flags in error integer fields that look like decimal values" do
    variables = VARIABLES.clone
    variables["DIAGNOSIS"][:normalized_type] = :integer
    variables["DIAGNOSIS"][:min_value] = 6
    variables["DIAGNOSIS"][:max_value] = 100
    process_with_expected_error("SUBJID,Diagnosis\r\n1,7.0",
      "The value '7.0' for 'Diagnosis' (1st row) should be an integer, not a decimal.",
      variables)
  end

  it "allows integer fields to have missing value" do
    variables = VARIABLES.clone
    variables["DIAGNOSIS"][:normalized_type] = :integer
    variables["DIAGNOSIS"][:min_value] = 6
    variables["DIAGNOSIS"][:max_value] = 100
    variables["DIAGNOSIS"][:values] = { "." => "Missing", "NA" => "Not Applicable" }
    variables["DIAGNOSIS"][:original_values] = { "." => "Missing", "NA" => "Not Applicable" }
    process_with_expected_success("SUBJID,Diagnosis\r\n1,.", variables)
  end

  it "flags in error integer fields that contain alphabetic characters" do
    variables = VARIABLES.clone
    variables["DIAGNOSIS"][:normalized_type] = :integer
    variables["DIAGNOSIS"][:min_value] = 6
    variables["DIAGNOSIS"][:max_value] = 100
    process_with_expected_error("SUBJID,Diagnosis\r\n1,7a",
      "The value '7a' for 'Diagnosis' (1st row) should be an integer, but appears to have non-numeric characters.",
      variables)
  end

  it "flags in error encoded fields that have an unknown value" do
    variables = VARIABLES.clone
    variables["DIAGNOSIS"][:normalized_type] = :encoded
    variables["DIAGNOSIS"][:values] = { "TEST1" => "VAL1", "TEST2" => "VAL2" }
    variables["DIAGNOSIS"][:original_values] = { "Test1" => "VAL1", "Test2" => "VAL2" }
    process_with_expected_error("SUBJID,Diagnosis\r\n1,TEST3",
      "The value 'TEST3' for the variable 'Diagnosis' (1st row) is not listed in the data dictionary.  It should be one of the following: Test1, Test2",
      variables)
  end

  it "flags with a warning encoded fields that have a known value but mismatched case" do
    variables = VARIABLES.clone
    variables["DIAGNOSIS"][:normalized_type] = :encoded
    values = { "TEST1" => "VAL1", "TEST2" => "VAL2" }
    variables["DIAGNOSIS"][:values] = values
    variables["DIAGNOSIS"][:original_values] = values
    process_with_expected_warning("SUBJID,Diagnosis\r\n1,test1",
      "The value 'test1' for the variable 'Diagnosis' (1st row) is found, but does not match exactly because of capitalization (should be 'TEST1').",
      variables)
  end

  def process_with_expected_warning data, expected_warning, variables
    validation = EMERGE::Phenotype::DataFileValidator.new(data, variables, :csv).validate
    puts validation[:errors] unless validation[:errors].length == 0
    validation[:errors].length.should == 0
    validation[:warnings].length.should be > 0
    result = validation[:warnings].include?(expected_warning)
    puts validation[:warnings] unless result
    result.should be_true
  end

  def process_with_expected_error data, expected_error, variables
    validation = EMERGE::Phenotype::DataFileValidator.new(data, variables, :csv).validate
    validation[:errors].length.should be > 0
    result = validation[:errors].include?(expected_error)
    puts validation[:errors] unless result
    result.should be_true
  end

  def process_with_expected_success data, variables
    validation = EMERGE::Phenotype::DataFileValidator.new(data, variables, :csv).validate
    puts validation[:errors] unless validation[:errors].blank?
    validation[:errors].length.should eql 0
    validation[:warnings].length.should eql 0
  end
end