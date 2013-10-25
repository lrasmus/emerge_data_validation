require 'validation/file_processor'

module EMERGE
  module Phenotype
    # Performs validation of a data file, according to the pre-defined rules
    #
    # Author::    Luke Rasmussen (mailto:luke.rasmussen@northwestern.edu)
    class BaseValidator
      def initialize(data, file_type, delimiter = :csv)
        @file = FileProcessor.new(data, file_type, delimiter)
        @results = {:errors => Hash.new, :warnings => Hash.new}
        initialize_results_container_collection(:errors)
        initialize_results_container_collection(:warnings)
      end

      def results
        @results
      end

      def rows_exist?
        result = !(@file.nil? or @file.headers.blank? or @file.data.blank?)
        add_file_error("No rows containing data could be found") unless result
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
          display_index = row_index + 1
          add_row_warning(display_index, "Row #{display_index} appears to be blank and should be removed.") if is_blank_row?(row)
        end
      end

      def add_file_error message
        add_results_message :errors, :file, message, nil
      end

      def add_file_warning message
        add_results_message :warnings, :file, message, nil
      end

      def add_row_error row_index, message
        add_results_message :errors, :rows, message, row_index
      end

      def add_row_warning row_index, message
        add_results_message :warnings, :rows, message, row_index
      end

      def add_column_error column_index, message
        add_results_message :errors, :columns, message, column_index
      end

      def add_column_warning column_index, message
        add_results_message :warnings, :columns, message, column_index
      end

      private

      def add_results_message collection, type, message, index
        if type == :file
          @results[collection][type].push(message)
        else
          @results[collection][type][index] = [] unless @results[collection][type].has_key?(index)
          @results[collection][type][index].push(message)
        end
      end

      def initialize_results_container_collection collection
        @results[collection][:file] = []
        @results[collection][:rows] = Hash.new
        @results[collection][:columns] = Hash.new
      end
    end
  end
end