require 'spec_helper'
require 'validation/data_dictionary_validator'

describe EMERGE::Phenotype::DataDictionaryValidator do
  it "flags in error a file with only one row" do
    process_with_expected_file_error("VARNAME,VARDESC,TYPE,REPEATED MEASURE,REQUIRED\r\n", "No rows containing data could be found")
  end

  it "flags in error a file missing the varname column" do
    process_with_expected_file_error("VARDESC,TYPE,REPEATED MEASURE,REQUIRED\r\nData1,Data2,Data3,Data4", "The VARNAME column is missing and is required")
  end

  it "warns when a column is missing" do
    process_with_expected_file_error("VARNAME\r\nData1", "The VARDESC column is missing and is required")
  end

  it "warns when a column is out of the expected order" do
    process_with_expected_column_warning("VARNAME,SOURCE,VARDESC,TYPE,REPEATED MEASURE,REQUIRED\r\nData1,Data2,Data3,Integer,Yes,No",
      "The VARDESC column is normally the 2nd column but in this dictionary is the 3rd", 3)
  end

  it "warns when an extra column exists" do
    process_with_expected_column_warning("VARNAME,VARDESC,SOURCE,SOURCE ID,DOCFILE,TYPE,UNITS,MIN,MAX,RESOLUTION,REPEATED MEASURE,REQUIRED,COMMENT1,COMMENT2,ExtraColumn,VALUES\r\nData1,Data2,Data3,Data4,Data5,Integer,UNITS,MIN,MAX,RESOLUTION,Yes,Yes",
      "The 15th column, ExtraColumn, is not a standard column in data dictionaries", 15)
  end

  it "processes a standard eMERGE data dictionary" do
    content = File.read("./spec/data/sample_data_dictionary.csv")
    validator = EMERGE::Phenotype::DataDictionaryValidator.new(content, :csv)
    results = validator.validate
    puts results[:errors][:rows] unless results[:errors][:rows].length == 0
    results[:errors][:rows].length.should == 0
    puts results[:warnings][:rows] unless results[:warnings][:rows].length == 0
    results[:warnings][:rows].length.should == 0
  end

  it "stores details for each variable" do
    validation = EMERGE::Phenotype::DataDictionaryValidator.new("VARNAME,VARDESC,SOURCE,SOURCE ID,DOCFILE,TYPE,UNITS,MIN,MAX,RESOLUTION,REPEATED MEASURE,REQUIRED,COMMENT1,COMMENT2,VALUES
Valid_Variable,VARDESC,SOURCE,SOURCE ID,DOCFILE,Integer,Units,3,5,RESOLUTION,No,Yes,COMMENT1,COMMENT2,TMP=Test;TMP2=15", :csv)
    results = validation.validate
    results[:errors][:rows].length.should eql 0
    validation.variables["VALID_VARIABLE"][:row].should eql 1
    validation.variables["VALID_VARIABLE"][:original_name].should eql "Valid_Variable"
    validation.variables["VALID_VARIABLE"][:values].length.should eql 2
    validation.variables["VALID_VARIABLE"][:normalized_type].should eql :integer
    validation.variables["VALID_VARIABLE"][:min_value].should eql 3
    validation.variables["VALID_VARIABLE"][:max_value].should eql 5
  end

  describe "flags in error rows that don't validate" do
    it "VARNAME with spaces" do
      process_with_expected_row_error("VARNAME,VARDESC,SOURCE,SOURCE ID,DOCFILE,TYPE,UNITS,MIN,MAX,RESOLUTION,REPEATED MEASURE,REQUIRED,COMMENT1,COMMENT2,VALUES,
Invalid variable,VARDESC,SOURCE,SOURCE ID,DOCFILE,TYPE,UNITS,MIN,MAX,RESOLUTION,REPEATED MEASURE,REQUIRED,COMMENT1,COMMENT2,VALUES
valid_variable,VARDESC,SOURCE,SOURCE ID,DOCFILE,TYPE,UNITS,MIN,MAX,RESOLUTION,REPEATED MEASURE,REQUIRED,COMMENT1,COMMENT2,VALUES",
        "'Invalid variable' (1st row), column 'VARNAME' (value = 'Invalid variable') is invalid: Variable names should not contain spaces (including at the beginning or end of the variable name)", 1)
    end

    it "TYPE" do
      process_with_expected_row_error("VARNAME,VARDESC,SOURCE,SOURCE ID,DOCFILE,TYPE,UNITS,MIN,MAX,RESOLUTION,REPEATED MEASURE,REQUIRED,COMMENT1,COMMENT2,VALUES,
valid_variable,VARDESC,SOURCE,SOURCE ID,DOCFILE,Integer,UNITS,MIN,MAX,RESOLUTION,REPEATED MEASURE,REQUIRED,COMMENT1,COMMENT2,VALUES
valid_variable2,VARDESC,SOURCE,SOURCE ID,DOCFILE,Unknown,UNITS,MIN,MAX,RESOLUTION,REPEATED MEASURE,REQUIRED,COMMENT1,COMMENT2,VALUES",
        "'valid_variable2' (2nd row), column 'TYPE' (value = 'Unknown') is invalid: The variable type is not recognized", 2)
    end
  end

  it "detects missing unit" do
    process_with_expected_row_error("VARNAME,VARDESC,SOURCE,SOURCE ID,DOCFILE,TYPE,UNITS,MIN,MAX,RESOLUTION,REPEATED MEASURE,REQUIRED,COMMENT1,COMMENT2,VALUES
valid_variable,VARDESC,SOURCE,SOURCE ID,DOCFILE,Decimal,,,,RESOLUTION,No,No,COMMENT1,COMMENT2,VALUES",
      "'valid_variable' (1st row) is missing units - this is required for variables of type 'Decimal'", 1)
  end

  it "detects missing min" do
    process_with_expected_row_error("VARNAME,VARDESC,SOURCE,SOURCE ID,DOCFILE,TYPE,UNITS,MIN,MAX,RESOLUTION,REPEATED MEASURE,REQUIRED,COMMENT1,COMMENT2,VALUES
valid_variable,VARDESC,SOURCE,SOURCE ID,DOCFILE,Decimal,Units,,,RESOLUTION,No,No,COMMENT1,COMMENT2,VALUES",
      "'valid_variable' (1st row) is missing a minimum value - this is required for variables of type 'Decimal'", 1)
  end

  it "detects missing max" do
    process_with_expected_row_error("VARNAME,VARDESC,SOURCE,SOURCE ID,DOCFILE,TYPE,UNITS,MIN,MAX,RESOLUTION,REPEATED MEASURE,REQUIRED,COMMENT1,COMMENT2,VALUES
valid_variable,VARDESC,SOURCE,SOURCE ID,DOCFILE,Decimal,Units,3,,RESOLUTION,No,No,COMMENT1,COMMENT2,VALUES",
      "'valid_variable' (1st row) is missing a maximum value - this is required for variables of type 'Decimal'", 1)
  end

  it "flags in error duplicate variables" do
    process_with_expected_row_error("VARNAME,VARDESC,SOURCE,SOURCE ID,DOCFILE,TYPE,UNITS,MIN,MAX,RESOLUTION,REPEATED MEASURE,REQUIRED,COMMENT1,COMMENT2,VALUES
valid_variable,VARDESC,SOURCE,SOURCE ID,DOCFILE,String,Units,3,,RESOLUTION,No,Yes,COMMENT1,COMMENT2,VALUE=1
Valid_Variable,VARDESC,SOURCE,SOURCE ID,DOCFILE,String,Units,3,,RESOLUTION,No,Yes,COMMENT1,COMMENT2,VALUE=2",
      "'Valid_Variable' (2nd row) appears to be a duplicate of the variable 'valid_variable' (1st row).", 2)
  end

  it "requires VALUES to be the last non-empty column" do
    process_with_expected_column_error("VARNAME,VARDESC,SOURCE,SOURCE ID,DOCFILE,TYPE,UNITS,MIN,MAX,RESOLUTION,REPEATED MEASURE,REQUIRED,VALUES,COMMENT1,COMMENT2,,,
Valid_Variable,VARDESC,SOURCE,SOURCE ID,DOCFILE,String,Units,3,,RESOLUTION,No,No,COMMENT1,COMMENT2,VALUES,,,",
      "The VALUES column (13th column) must be the last, non-empty column", 13)
    process_with_expected_column_error("VARNAME,VARDESC,SOURCE,SOURCE ID,DOCFILE,TYPE,UNITS,MIN,MAX,RESOLUTION,REPEATED MEASURE,REQUIRED,COMMENT1,COMMENT2,VALUES,,,Test
Valid_Variable,VARDESC,SOURCE,SOURCE ID,DOCFILE,String,Units,3,,RESOLUTION,No,No,COMMENT1,COMMENT2,VALUES,,,",
      "The VALUES column (15th column) must be the last, non-empty column", 15)
  end

  it "flags in error malformed VALUE entries" do
    process_with_expected_row_error("VARNAME,VARDESC,SOURCE,SOURCE ID,DOCFILE,TYPE,UNITS,MIN,MAX,RESOLUTION,REPEATED MEASURE,REQUIRED,COMMENT1,COMMENT2,VALUES
Valid_Variable,VARDESC,SOURCE,SOURCE ID,DOCFILE,String,Units,3,,RESOLUTION,No,No,COMMENT1,COMMENT2,.=Test;15",
      "Value '15' for variable 'Valid_Variable' (1st row) is invalid.  We are expecting something that looks like 'val=Description'", 1)
  end

  it "flags in error duplicate VALUE entries" do
    process_with_expected_row_error("VARNAME,VARDESC,SOURCE,SOURCE ID,DOCFILE,TYPE,UNITS,MIN,MAX,RESOLUTION,REPEATED MEASURE,REQUIRED,COMMENT1,COMMENT2,VALUES
Valid_Variable,VARDESC,SOURCE,SOURCE ID,DOCFILE,String,Units,3,,RESOLUTION,No,No,COMMENT1,COMMENT2,TMP=Test;tmp=Test2",
      "It appears that the value 'tmp=Test2' for variable 'Valid_Variable' (1st row) is a duplicate value for this variable.", 1)
  end

  it "flags in error optional variables without a Missing/NA value" do
    process_with_expected_row_error("VARNAME,VARDESC,SOURCE,SOURCE ID,DOCFILE,TYPE,UNITS,MIN,MAX,RESOLUTION,REPEATED MEASURE,REQUIRED,COMMENT1,COMMENT2,VALUES
Valid_Variable,VARDESC,SOURCE,SOURCE ID,DOCFILE,String,Units,3,,RESOLUTION,No,No,COMMENT1,COMMENT2,TMP=Test",
      "The optional variable 'Valid_Variable' (1st row) doesn't appear to have a 'Missing' or 'Not Applicable' value listed, and should be added.", 1)
  end

  def process_with_expected_file_warning data, expected_warning
    process_with_expected_warning data, expected_warning, :file, nil
  end

  def process_with_expected_row_warning data, expected_warning, index
    process_with_expected_warning data, expected_warning, :rows, index
  end

  def process_with_expected_column_warning data, expected_warning, index
    process_with_expected_warning data, expected_warning, :columns, index
  end

  def process_with_expected_warning data, expected_warning, collection, index
    validation = EMERGE::Phenotype::DataDictionaryValidator.new(data, :csv).validate
    puts validation[:errors][collection] unless validation[:errors][collection].length == 0
    validation[:errors][collection].length.should == 0
    validation[:warnings][collection].length.should be > 0
    if index.nil?
      result = validation[:warnings][collection].include?(expected_warning)
    else
      result = validation[:warnings][collection][index].include?(expected_warning)
    end
    puts validation[:warnings][collection] unless result
    result.should be_true
  end

  def process_with_expected_file_error data, expected_error
    process_with_expected_error data, expected_error, :file, nil
  end

  def process_with_expected_row_error data, expected_error, index
    process_with_expected_error data, expected_error, :rows, index
  end

  def process_with_expected_column_error data, expected_error, index
    process_with_expected_error data, expected_error, :columns, index
  end

  def process_with_expected_error data, expected_error, collection, index
    validation = EMERGE::Phenotype::DataDictionaryValidator.new(data, :csv).validate
    validation[:errors][collection].length.should be > 0
    if index.nil?
      result = validation[:errors][collection].include?(expected_error)
    else
      result = validation[:errors][collection][index].include?(expected_error)
    end
    puts validation[:errors][collection] unless result
    result.should be_true
  end
end