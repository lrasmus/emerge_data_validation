require 'spec_helper'
require 'validation/file_processor'

describe EMERGE::Phenotype::FileProcessor do
  describe "clean_lines" do
    it "ignores commented lines" do
      file_content = "Data Line 1\r\n#Comment line 1\r\nData Line 2\r\n  #Comment line 2\r\nData Line #3"
      processor = EMERGE::Phenotype::FileProcessor.new(file_content, :dictionary)
      lines = processor.clean_lines
      expect(lines.length).to eq 3
    end

    it "handles Windows newlines" do
      processor = EMERGE::Phenotype::FileProcessor.new("Data Line 1\r\nData Line #2", :dictionary)
      expect(processor.clean_lines.length).to eq 2
    end

    it "handles UNIX newlines" do
      processor = EMERGE::Phenotype::FileProcessor.new("Data Line 1\rData Line #2", :dictionary)
      expect(processor.clean_lines.length).to eq 2
    end
  end

  describe "process" do
    it "Loads CSV lines" do
      processor = EMERGE::Phenotype::FileProcessor.new("Col1,Col2,Col3\r\nData1,Data2,Data3", :dictionary)
      processor.process
      expect(processor.headers.length).to eq 3
    end
  end
end