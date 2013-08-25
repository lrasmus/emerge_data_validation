require 'validation/file_processor'

module EMERGE
  module Phenotype
    # Performs validation of a data file, according to the pre-defined rules
    #
    # Author::    Luke Rasmussen (mailto:luke.rasmussen@northwestern.edu)
    class BaseValidator
      def initialize(data, file_type, delimiter = :csv)
        @file = FileProcessor.new(data, file_type, delimiter)
        @results = {:errors => [], :warnings => []}
      end

      def rows_exist?
        result = !(@file.nil? or @file.headers.blank? or @file.data.blank?)
        @results[:errors].push("No rows containing data could be found") unless result
        result
      end

      def convert_string_to_number value, normalized_type
        return value.to_i if normalized_type == :integer
        return value.to_f if normalized_type == :decimal
        value
      end
    end
  end
end