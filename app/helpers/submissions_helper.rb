module SubmissionsHelper
  def get_data_from_params data_dictionary_param, data_file_param
    data_dictionary = data_dictionary_param.read unless data_dictionary_param.blank?
    data_file = data_file_param.read unless data_file_param.blank?

    unless data_dictionary.blank?
      dd_processor = EMERGE::Phenotype::DataDictionaryValidator.new data_dictionary, :csv, ValidationParameters['error_limit']
      @data_dictionary_results = dd_processor.validate
      @data_dictionary_results[:file_name] = data_dictionary_param.original_filename
      unless data_file.blank?
        df_processor = EMERGE::Phenotype::DataFileValidator.new data_file, dd_processor.variables, :csv, ValidationParameters['error_limit']
        @data_file_results = df_processor.validate
        @data_file_results[:file_name] = data_file_param.original_filename
      end
    end
  end

  def results_collection_has_data? collection
    collection.any?{ |x| x[1].length > 0}
  end
end
