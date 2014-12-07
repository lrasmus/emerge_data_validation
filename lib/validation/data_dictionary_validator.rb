require 'validation/base_validator'
require 'validation/file_processor'

module EMERGE
  module Phenotype
    # Performs validation of a data dictionary file, according to the pre-defined rules
    #
    # Author::    Luke Rasmussen (mailto:luke.rasmussen@northwestern.edu)
    class DataDictionaryValidator < BaseValidator
      EXPECTED_COLUMNS = ["VARNAME", "VARDESC", "SOURCE", "SOURCE ID", "DOCFILE", "TYPE", "UNITS", "MIN", "MAX", "RESOLUTION", "REPEATED MEASURE", "REQUIRED", "COMMENT1", "COMMENT2", "VALUES"]
      REQUIRED_DATA_COLUMNS = ["VARNAME", "VARDESC", "TYPE", "REPEATED MEASURE", "REQUIRED"]
      COLUMN_VALIDATION_REGEX = [
        [/^[\S]*$/i, "Variable names should not contain spaces (including at the beginning or end of the variable name)"], #Varname
        nil, # Vardesc
        nil, # Source
        nil, # Source ID
        nil, # Docfile
        [/String|Decimal|Integer|Decimal, encoded value|Integer, encoded value|Encoded value|String, encoded value/i, "The variable type is not recognized"], # Type
        nil, # Units
        nil, # Min
        nil, # Max
        nil, # Resolution
        [/Yes|No/i, "Please enter 'Yes' or 'No' for Repeated Measure"], # Repeated measure
        [/Yes|No/i, "Please enter 'Yes' or 'No' for Required"], # Required
        nil, # Comment 1
        nil, # Comment 2
        nil  # Values
      ]

      def initialize(data_dictionary_data, delimiter = :csv, error_limit = nil)
        super(data_dictionary_data, :data_dictionary, delimiter, error_limit)
        @variables = Hash.new
        @values_column_valid = false
        #@values = Hash.new
      end

      def validate
        # Start by performing checks that would prevent us from doing any additional processing.
        return @results unless rows_exist?
        return @results unless variable_name_column_exists?

        # Validate the columns
        check_required_columns
        check_header_columns

        check_values_column_position

        # Validate rows & values in the rows
        row_index = 0
        CSV.parse(@file.file_content, {:headers => true, :skip_blanks => true}) do |row|
          validate_row(row, row_index)
          check_constraints_for_types_in_row(row, row_index)
          check_unique_variable_in_row(row, row_index)
          check_values_in_row(row, row_index)
          set_variable_constraints_in_row(row, row_index)
          check_blank_row(row, row_index)

          row_index = row_index + 1
        end

        @results
      end

      def variables
        @variables
      end

      def variable_name_column_exists?
        result = @file.headers.include?(EXPECTED_COLUMNS[0])
        add_file_error("The #{EXPECTED_COLUMNS[0]} column is missing and is required") unless result
        result
      end

      def check_required_columns
        REQUIRED_DATA_COLUMNS.each_with_index do |header, index|
          found_index = @file.headers.index(header)
          result ||= !found_index.nil?
          add_file_error("The #{header} column is missing and is required") if found_index.nil?
        end
      end

      def check_header_columns
        # Compare against the standard set of headers that we expect
        EXPECTED_COLUMNS.each_with_index do |header, index|
          found_index = @file.headers.index(header)
          if found_index.nil?
            add_file_warning("The #{header} column is missing and should be included")
          elsif !found_index.nil? and found_index != index
            display_index = found_index + 1
            add_column_warning(display_index, "The #{header} column is normally the #{(index + 1).ordinalize} column but in this dictionary is the #{display_index.ordinalize}")
          end
        end

        # Check for extra columns that are included
        @file.headers.each_with_index do |header, index|
          found_index = EXPECTED_COLUMNS.index(header)
          display_index = index + 1
          add_column_warning(display_index, "The #{display_index.ordinalize} column, #{header}, is not a standard column in data dictionaries") if found_index.nil?
        end
      end

      def validate_row(row, row_index)
        EXPECTED_COLUMNS.each_with_index do |header, col_index|
          found_index = @file.headers.index(header)
          next if found_index.nil? or COLUMN_VALIDATION_REGEX[col_index].nil?
          validation = COLUMN_VALIDATION_REGEX[col_index]
          unless is_blank_row?(row)
            display_index = row_index + 1
            add_row_error(display_index, "'#{row[0]}' (#{display_index.ordinalize} row), column '#{header}' (value = '#{row[found_index]}') is invalid: #{validation[1]}") unless validation[0].match(row[found_index])
          end
        end
      end

      def check_unique_variable_in_row(row, row_index)
        unless is_blank_row?(row)
          variable_name = row[0].upcase
          if @variables.has_key?(variable_name)
            display_index = row_index + 1
            add_row_error(display_index, "'#{row[0]}' (#{display_index.ordinalize} row) appears to be a duplicate of the variable '#{@variables[row[0].upcase][:original_name]}' (#{@variables[row[0].upcase][:row].ordinalize} row).")
          else
            @variables[variable_name] = {:values => nil, :row => (row_index + 1), :original_name => row[0], :normalized_type => nil}
          end
        end
      end

      def check_values_column_position
        # If the VALUES column is present (it isn't required), it must be the last non-blank column.  This is because the way data ditionaries
        # are created & exported to CSV by Excel, we'll see columns like "VALUES,,,,,"
        found_index = @file.headers.index("VALUES")
        @values_column_valid = !found_index.nil?
        return if found_index.nil?
        @file.headers[(found_index+1)..@file.headers.length].each_with_index do |header, index|
          unless header.nil? or header.strip.blank?
            display_index = found_index + 1
            add_column_error(display_index, "The VALUES column (#{display_index.ordinalize} column) must be the last, non-empty column")
            @values_column_valid = false
            break
          end
        end
      end

      def check_constraints_for_types_in_row(row, row_index)
        type_index = @file.headers.index("TYPE")
        return if type_index.nil?
        units_index = @file.headers.index("UNITS")
        min_index = @file.headers.index("MIN")
        max_index = @file.headers.index("MAX")
        if (row[type_index] == "Decimal" or row[type_index] == "Integer")
          display_index = row_index + 1
          add_row_error(display_index, "'#{row[0]}' (#{display_index.ordinalize} row) is missing units - this is required for variables of type '#{row[type_index]}'") unless units_index.nil? or !row[units_index].blank?
          add_row_error(display_index, "'#{row[0]}' (#{display_index.ordinalize} row) is missing a minimum value - this is required for variables of type '#{row[type_index]}'") unless min_index.nil? or !row[min_index].blank?
          add_row_error(display_index, "'#{row[0]}' (#{display_index.ordinalize} row) is missing a maximum value - this is required for variables of type '#{row[type_index]}'") unless max_index.nil? or !row[max_index].blank?
        end
      end

      def check_values_in_row(row, row_index)
        return unless @values_column_valid
        values_column_index = @file.headers.index("VALUES")
        required_column_index = @file.headers.index("REQUIRED")
        unless is_blank_row?(row)
          unique_values = Hash.new
          original_values = Hash.new
          variable = row[0]
          variable_key = variable.upcase
          values = row.fields[values_column_index].split(';') unless row.fields[values_column_index].nil?
          is_required = !(/Yes/i.match(row[required_column_index]).nil?)
          missing_na_value_found = false
          display_index = row_index + 1
          unless values.blank?
            values.each_with_index do |value, var_index|
              value ||= ""
              value_parts = value.split('=')
              add_row_error(display_index, "Value '#{value}' for variable '#{variable}' (#{display_index.ordinalize} row) is invalid.  We are expecting something that looks like 'val=Description'") unless value_parts.length == 2
              found_item = unique_values[value_parts[0].upcase]
              if (found_item.nil?)
                unique_values[value_parts[0].upcase] = value_parts[1]
                original_values[value_parts[0]] = value_parts[1]
              else
                add_row_error(display_index, "It appears that the value '#{value}' for variable '#{variable}' (#{display_index.ordinalize} row) is a duplicate value for this variable.")
              end

              missing_na_value_found = !(/.*missing.*|not applicable|NA|not assessed/i.match(value_parts[1]).nil?) unless is_required or missing_na_value_found
            end
          end

          unless @variables[variable_key].nil?
            @variables[variable_key][:values] = unique_values
            @variables[variable_key][:original_values] = original_values
          end

          # Variables that are not required must define a missing or not applicable value
          if !is_required and !missing_na_value_found
            add_row_error(display_index, "The optional variable '#{variable}' (#{display_index.ordinalize} row) doesn't appear to have a 'Missing' or 'Not Applicable' value listed, and should be added.")
          end
        end
      end

      def set_variable_constraints_in_row(row, row_index)
        type_index = @file.headers.index("TYPE")
        return if type_index.nil?
        min_index = @file.headers.index("MIN")
        max_index = @file.headers.index("MAX")
        unless is_blank_row?(row)
          variable_key = row[0].upcase
          normalized_type = get_normalized_type(row[type_index])
          @variables[variable_key][:normalized_type] = normalized_type
          @variables[variable_key][:min_value] = min_index.nil? ? nil : convert_string_to_number(row[min_index], normalized_type)
          @variables[variable_key][:max_value] = max_index.nil? ? nil : convert_string_to_number(row[max_index], normalized_type)
        end
      end

      private

      def get_normalized_type type
        return :encoded if (type =~ /.*Encoded.*/i)
        return :integer if (type =~ /^Integer$/i)
        return :decimal if (type =~ /^Decimal$/i)
        return :string if (type =~ /^String$/i)
      end
    end
  end
end