require 'validation/base_validator'
require 'validation/file_processor'

module EMERGE
  module Phenotype
    # Performs validation of a data file, according to the pre-defined rules
    #
    # Author::    Luke Rasmussen (mailto:luke.rasmussen@northwestern.edu)
    class DataFileValidator < BaseValidator
      def initialize(data, variables, delimiter = :csv, error_limit = nil)
        @variables = variables
        super(data, :data_file, delimiter, error_limit)
      end

      def validate
        # Start by performing checks that would prevent us from doing any additional processing.
        return @results unless rows_exist?
        check_variables_used
        check_variable_order

        row_index = 0
        CSV.parse(@file.file_content, {:headers => true, :skip_blanks => true}) do |row|
          next if check_blank_row(row, row_index)
          break if at_result_collection_limit?(:errors, :rows)
          check_missing_data_for_row(row, row_index)
          check_numeric_ranges_for_row(row, row_index)
          check_encoded_values_for_row(row, row_index)

          row_index = row_index + 1
        end

        @results
      end

      def check_variables_used
        @file.headers.each_with_index do |header, index|
          display_index = index + 1
          if header.nil? or header.strip.blank?
            add_column_error(display_index, "The #{display_index.ordinalize} column has a blank header - please set the header and define it in the data dictionary.")
          elsif !@variables.has_key?(header.upcase)
            add_column_error(display_index, "The variable '#{header}' (#{display_index.ordinalize} column) is not defined in the data dictionary.")
          end
        end

        formatted_headers = @file.headers.map{|x| x.blank? ? "" : x.upcase}
        @variables.keys.each do |variable|
          add_file_error("The variable '#{@variables[variable][:original_name]}' is defined in the data dictionary, but does not appear in the data file.") unless formatted_headers.include?(variable)
        end
      end

      def check_variable_order
        formatted_headers = @file.headers.map{|x| x.blank? ? "" : x.upcase}
        formatted_headers.each_with_index do |header, index|
          next unless @variables.has_key?(header)
          display_index = index + 1
          add_column_warning(display_index, "The variable '#{@file.headers[index]}' (#{display_index.ordinalize} column) is the #{(@variables[header][:variable_num]).ordinalize} variable in the data dictionary.  It's recommended to have variables in the same order.") if (index+1) != @variables[header][:variable_num]
        end
      end

      def check_missing_data_for_row row, row_index
        display_index = row_index + 1
        row.each_with_index do |field, field_index|
          add_row_error(display_index, "A value for '#{@file.headers[field_index]}' (#{display_index.ordinalize} row) is blank, however it is best practice to provide a value to explicitly define missing data.") if field[1].nil? or field[1].strip.blank?
        end
      end

      def check_numeric_ranges_for_row row, row_index
        display_index = row_index + 1
        row.each_with_index do |field, field_index|
          next if field[0].nil?
          variable_name = field[0].upcase
          variable = @variables[variable_name]
          next if variable.nil?
          next unless variable[:normalized_type] == :integer or variable[:normalized_type] == :decimal
          value = convert_string_to_number(field[1], variable[:normalized_type])
          if (variable[:normalized_type] == :integer)
            next if !variable[:values].blank? and variable[:values].has_key?(field[1])
            if field[1] =~ /\./
              add_row_error(display_index, "The value '#{field[1]}' for '#{@file.headers[field_index]}' (#{display_index.ordinalize} row) should be an integer, not a decimal.")
            elsif (/[\D]+/ === field[1])
              add_row_error(display_index, "The value '#{field[1]}' for '#{@file.headers[field_index]}' (#{display_index.ordinalize} row) should be an integer, but appears to have non-numeric characters.")
            end
          end

          # We only perform the check if both min and max are specified.  They are required in conjunction.
          unless (variable[:min_value].nil? or variable[:max_value].nil? or value.nil?)
            if (value < variable[:min_value] or value > variable[:max_value])
              add_row_error(display_index, "The value '#{value}' for '#{@file.headers[field_index]}' (#{display_index.ordinalize} row) is outside of the range defined in the data dictionary (#{variable[:min_value]} to #{variable[:max_value]}).")
            end
          end
        end
      end

      def check_encoded_values_for_row row, row_index
        display_index = row_index + 1
        row.each_with_index do |field, field_index|
          next if field[0].nil?
          variable_name = field[0].upcase
          variable = @variables[variable_name]
          next if variable.nil? or variable[:normalized_type] != :encoded # Skip if we don't have a list of values to check against, or this isn't an encoded type
          next if field[1].nil?
          formatted_value = field[1].upcase
          if !variable[:values].has_key?(formatted_value)
            add_row_error(display_index, "The value '#{field[1]}' for the variable '#{@file.headers[field_index]}' (#{display_index.ordinalize} row) is not listed in the data dictionary.  #{format_list_of_values_for_error(variable[:original_values])}")
          elsif !variable[:original_values].has_key?(field[1])
            correct_val = variable[:original_values].find{|val| val[0].casecmp(field[1]) == 0}
            add_row_warning(display_index, "The value '#{field[1]}' for the variable '#{@file.headers[field_index]}' (#{display_index.ordinalize} row) is found, but does not match exactly because of capitalization (should be '#{correct_val[0]}').")
          end
        end
      end

      def format_list_of_values_for_error values
        if values.length < 6
          return "It should be one of the following: #{values.keys.join(', ')}"
        end
        ""
      end
    end
  end
end