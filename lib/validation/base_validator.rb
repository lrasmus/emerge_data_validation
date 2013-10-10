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
        if normalized_type == :integer or normalized_type == :decimal
          return nil unless (/^[-]?[\d]+(\.[\d]+){0,1}$/ === value)
          return nil if value.strip.blank?
          return value.to_i if normalized_type == :integer
          return value.to_f if normalized_type == :decimal
        end
        nil
      end

      def is_blank_row? row
        row.each_with_index do |cell, index|
          return false unless cell[1].nil? or cell[1].strip == ""
        end
        true
      end

      def identify_blank_rows
        @file.data.each_with_index do |row, row_index|
          @results[:warnings].push("Row #{row_index+1} appears to be blank and should be removed.") if is_blank_row?(row)
        end
      end
    end
  end
end