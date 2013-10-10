require 'validation/data_dictionary_validator'
require 'validation/data_file_validator'
require "active_support/core_ext/integer/inflections"

namespace :validate do
  desc "Validate a data dictionary"
  task :data_dictionary, :filename do |task, params|
    content,validator = prepare_dictionary_validator params[:filename]
    puts validator.validate
  end

  desc "Validate a data file"
  task :data_file => :environment do
    dd_content, dd_validator = prepare_dictionary_validator ENV["dictionary_file_path"]
    dd_results = dd_validator.validate
    if (dd_results[:errors].length > 0)
      puts "Please correct the following issues with your data dictionary, and then run the validator again"
      puts dd_results
    else
      df_content, df_validator = prepare_file_validator ENV["data_file_path"], dd_validator.variables
      puts df_validator.validate
    end
  end
end

private

  def prepare_dictionary_validator filename
    content = File.read(filename)
    validator = EMERGE::Phenotype::DataDictionaryValidator.new(content, :csv)
    [content, validator]
  end

  def prepare_file_validator filename, dd_variables
    content = File.read(filename)
    validator = EMERGE::Phenotype::DataFileValidator.new(content, dd_variables, :csv)
    [content, validator]
  end