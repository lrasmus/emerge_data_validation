require 'validation/data_dictionary_validator'
require "active_support/core_ext/integer/inflections"

namespace :validate do
  desc "Validate a data dictionary"
  task :data_dictionary, :filename do |task, params|
    #puts params[:filename]
    content = File.read(params[:filename])
    validator = EMERGE::Phenotype::DataDictionaryValidator.new(content, :csv)
    puts validator.validate
  end
end
