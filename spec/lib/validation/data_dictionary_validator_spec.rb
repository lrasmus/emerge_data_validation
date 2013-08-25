require 'spec_helper'
require 'validation/data_dictionary_validator'

describe EMERGE::Phenotype::DataDictionaryValidator do
  it "flags in error a file with only one row" do
    process_with_expected_error("VARNAME,VARDESC,TYPE,REPEATED MEASURE,REQUIRED\r\n", "No rows containing data could be found")
  end

  it "flags in error a file missing the varname column" do
    process_with_expected_error("VARDESC,TYPE,REPEATED MEASURE,REQUIRED\r\nData1,Data2,Data3,Data4", "The VARNAME column is missing and is required")
  end

  it "warns when a column is missing" do
    process_with_expected_error("VARNAME\r\nData1", "The VARDESC column is missing and is required")
  end

  it "warns when a column is out of the expected order" do
    process_with_expected_warning("VARNAME,SOURCE,VARDESC,TYPE,REPEATED MEASURE,REQUIRED\r\nData1,Data2,Data3,Integer,Yes,No", "The VARDESC column is normally the 2nd column but in this dictionary is the 3rd")
  end

  it "warns when an extra column exists" do
    process_with_expected_warning("VARNAME,VARDESC,SOURCE,SOURCE ID,DOCFILE,TYPE,UNITS,MIN,MAX,RESOLUTION,REPEATED MEASURE,REQUIRED,COMMENT1,COMMENT2,ExtraColumn,VALUES,\r\nData1,Data2,Data3,Data4,Data5,Integer,UNITS,MIN,MAX,RESOLUTION,Yes,Yes,", 
      "The 15th column, ExtraColumn, is not a standard column in data dictionaries")
  end

  it "processes a standard eMERGE data dictionary" do
    content = File.read("./spec/data/sample_data_dictionary.csv")
    validator = EMERGE::Phenotype::DataDictionaryValidator.new(content, :csv)
    results = validator.validate
    puts results[:errors] unless results[:errors].length == 0
    results[:errors].length.should == 0
    results[:warnings].length.should == 0
  end

  it "stores the values for each variable" do
    validation = EMERGE::Phenotype::DataDictionaryValidator.new("VARNAME,VARDESC,SOURCE,SOURCE ID,DOCFILE,TYPE,UNITS,MIN,MAX,RESOLUTION,REPEATED MEASURE,REQUIRED,COMMENT1,COMMENT2,VALUES,
Valid_Variable,VARDESC,SOURCE,SOURCE ID,DOCFILE,String,Units,3,,RESOLUTION,No,Yes,COMMENT1,COMMENT2,TMP=Test;TMP2=15,", :csv)
    results = validation.validate
    puts results[:errors]
    results[:errors].length.should eql 0
    validation.variables["VALID_VARIABLE"][:values].length.should eql 2
  end

  describe "flags in error rows that don't validate" do
    it "VARNAME" do
      process_with_expected_error("VARNAME,VARDESC,SOURCE,SOURCE ID,DOCFILE,TYPE,UNITS,MIN,MAX,RESOLUTION,REPEATED MEASURE,REQUIRED,COMMENT1,COMMENT2,VALUES,
Invalid variable,VARDESC,SOURCE,SOURCE ID,DOCFILE,TYPE,UNITS,MIN,MAX,RESOLUTION,REPEATED MEASURE,REQUIRED,COMMENT1,COMMENT2,VALUES,
valid_variable,VARDESC,SOURCE,SOURCE ID,DOCFILE,TYPE,UNITS,MIN,MAX,RESOLUTION,REPEATED MEASURE,REQUIRED,COMMENT1,COMMENT2,VALUES,",
        "'Invalid variable' (1st row), column 'VARNAME' (value = 'Invalid variable') is invalid: Variable names should not contain spaces")
    end

    it "TYPE" do
      process_with_expected_error("VARNAME,VARDESC,SOURCE,SOURCE ID,DOCFILE,TYPE,UNITS,MIN,MAX,RESOLUTION,REPEATED MEASURE,REQUIRED,COMMENT1,COMMENT2,VALUES,
valid_variable,VARDESC,SOURCE,SOURCE ID,DOCFILE,Integer,UNITS,MIN,MAX,RESOLUTION,REPEATED MEASURE,REQUIRED,COMMENT1,COMMENT2,VALUES,
valid_variable2,VARDESC,SOURCE,SOURCE ID,DOCFILE,Unknown,UNITS,MIN,MAX,RESOLUTION,REPEATED MEASURE,REQUIRED,COMMENT1,COMMENT2,VALUES,",
        "'valid_variable2' (2nd row), column 'TYPE' (value = 'Unknown') is invalid: The variable type is not recognized")
    end
  end

  it "detects missing unit" do
    process_with_expected_error("VARNAME,VARDESC,SOURCE,SOURCE ID,DOCFILE,TYPE,UNITS,MIN,MAX,RESOLUTION,REPEATED MEASURE,REQUIRED,COMMENT1,COMMENT2,VALUES,
valid_variable,VARDESC,SOURCE,SOURCE ID,DOCFILE,Decimal,,,,RESOLUTION,No,No,COMMENT1,COMMENT2,VALUES,",
      "'valid_variable' (1st row) is missing units - this is required for variables of type 'Decimal'")
  end

  it "detects missing min" do
    process_with_expected_error("VARNAME,VARDESC,SOURCE,SOURCE ID,DOCFILE,TYPE,UNITS,MIN,MAX,RESOLUTION,REPEATED MEASURE,REQUIRED,COMMENT1,COMMENT2,VALUES,
valid_variable,VARDESC,SOURCE,SOURCE ID,DOCFILE,Decimal,Units,,,RESOLUTION,No,No,COMMENT1,COMMENT2,VALUES,",
      "'valid_variable' (1st row) is missing a minimum value - this is required for variables of type 'Decimal'")
  end

  it "detects missing max" do
    process_with_expected_error("VARNAME,VARDESC,SOURCE,SOURCE ID,DOCFILE,TYPE,UNITS,MIN,MAX,RESOLUTION,REPEATED MEASURE,REQUIRED,COMMENT1,COMMENT2,VALUES,
valid_variable,VARDESC,SOURCE,SOURCE ID,DOCFILE,Decimal,Units,3,,RESOLUTION,No,No,COMMENT1,COMMENT2,VALUES,",
      "'valid_variable' (1st row) is missing a maximum value - this is required for variables of type 'Decimal'")
  end

  it "flags in error duplicate variables" do
    process_with_expected_error("VARNAME,VARDESC,SOURCE,SOURCE ID,DOCFILE,TYPE,UNITS,MIN,MAX,RESOLUTION,REPEATED MEASURE,REQUIRED,COMMENT1,COMMENT2,VALUES,
valid_variable,VARDESC,SOURCE,SOURCE ID,DOCFILE,String,Units,3,,RESOLUTION,No,Yes,COMMENT1,COMMENT2,VALUE=1,
Valid_Variable,VARDESC,SOURCE,SOURCE ID,DOCFILE,String,Units,3,,RESOLUTION,No,Yes,COMMENT1,COMMENT2,VALUE=2,",
      "'Valid_Variable' (2nd row) appears to be a duplicate of the variable 'valid_variable' (1st row).")
  end

  it "requires VALUES to be the last non-empty column" do
    process_with_expected_error("VARNAME,VARDESC,SOURCE,SOURCE ID,DOCFILE,TYPE,UNITS,MIN,MAX,RESOLUTION,REPEATED MEASURE,REQUIRED,VALUES,COMMENT1,COMMENT2,,,
Valid_Variable,VARDESC,SOURCE,SOURCE ID,DOCFILE,String,Units,3,,RESOLUTION,No,No,COMMENT1,COMMENT2,VALUES,,,",
      "The VALUES column (13th column) must be the last, non-empty column")
    process_with_expected_error("VARNAME,VARDESC,SOURCE,SOURCE ID,DOCFILE,TYPE,UNITS,MIN,MAX,RESOLUTION,REPEATED MEASURE,REQUIRED,COMMENT1,COMMENT2,VALUES,,,Test
Valid_Variable,VARDESC,SOURCE,SOURCE ID,DOCFILE,String,Units,3,,RESOLUTION,No,No,COMMENT1,COMMENT2,VALUES,,,",
      "The VALUES column (15th column) must be the last, non-empty column")
  end

  it "flags in error malformed VALUE entries" do
    process_with_expected_error("VARNAME,VARDESC,SOURCE,SOURCE ID,DOCFILE,TYPE,UNITS,MIN,MAX,RESOLUTION,REPEATED MEASURE,REQUIRED,COMMENT1,COMMENT2,VALUES,
Valid_Variable,VARDESC,SOURCE,SOURCE ID,DOCFILE,String,Units,3,,RESOLUTION,No,No,COMMENT1,COMMENT2,.=Test;15,",
      "Value '15' for variable 'Valid_Variable' (1st row) is invalid.  We are expecting something that looks like 'val=Description'")
  end

  it "flags in error duplicate VALUE entries" do
    process_with_expected_error("VARNAME,VARDESC,SOURCE,SOURCE ID,DOCFILE,TYPE,UNITS,MIN,MAX,RESOLUTION,REPEATED MEASURE,REQUIRED,COMMENT1,COMMENT2,VALUES,
Valid_Variable,VARDESC,SOURCE,SOURCE ID,DOCFILE,String,Units,3,,RESOLUTION,No,No,COMMENT1,COMMENT2,TMP=Test;tmp=Test2,",
      "It appears that the value 'tmp=Test2' for variable 'Valid_Variable' (1st row) is a duplicate value for this variable.")
  end

  it "flags in error optional variables without a Missing/NA value" do
    process_with_expected_error("VARNAME,VARDESC,SOURCE,SOURCE ID,DOCFILE,TYPE,UNITS,MIN,MAX,RESOLUTION,REPEATED MEASURE,REQUIRED,COMMENT1,COMMENT2,VALUES,
Valid_Variable,VARDESC,SOURCE,SOURCE ID,DOCFILE,String,Units,3,,RESOLUTION,No,No,COMMENT1,COMMENT2,TMP=Test,",
      "The optional variable 'Valid_Variable' (1st row) doesn't appear to have a 'Missing' or 'Not Applicable' value listed, and should be added.")
  end
end

def process_with_expected_warning data, expected_warning
  validation = EMERGE::Phenotype::DataDictionaryValidator.new(data, :csv).validate
  puts validation[:errors] unless validation[:errors].length == 0
  validation[:errors].length.should == 0
  validation[:warnings].length.should be > 0
  result = validation[:warnings].include?(expected_warning)
  puts validation[:warnings] unless result
  result.should be_true
end

def process_with_expected_error data, expected_error
  validation = EMERGE::Phenotype::DataDictionaryValidator.new(data, :csv).validate
  validation[:errors].length.should be > 0
  result = validation[:errors].include?(expected_error)
  puts validation[:errors] unless result
  result.should be_true
end