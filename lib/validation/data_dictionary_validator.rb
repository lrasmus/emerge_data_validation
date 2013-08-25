require 'validation/file_processor'

module EMERGE
  module Phenotype
    # Performs validation of a data dictionary file, according to the pre-defined rules
    #
    # Author::    Luke Rasmussen (mailto:luke.rasmussen@northwestern.edu)
    class DataDictionaryValidator
      EXPECTED_COLUMNS = ["VARNAME", "VARDESC", "SOURCE", "SOURCE ID", "DOCFILE", "TYPE", "UNITS", "MIN", "MAX", "RESOLUTION", "REPEATED MEASURE", "REQUIRED", "COMMENT1", "COMMENT2", "VALUES"]
      REQUIRED_DATA_COLUMNS = ["VARNAME", "VARDESC", "TYPE", "REPEATED MEASURE", "REQUIRED"]
      COLUMN_VALIDATION_REGEX = [
        [/^[\S]*$/i, "Variable names should not contain spaces"], #Varname
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

      def initialize(data_dictionary_data, delimiter = :csv)
        @file = FileProcessor.new(data_dictionary_data, :data_dictionary, delimiter)
        @results = {:errors => [], :warnings => []}
        @variables = Array.new
        @values_column_valid = false
      end

      def validate
        # Start by performing checks that would prevent us from doing any additional processing.
        return @results unless rows_exist?
        return @results unless variable_name_column_exists?
        check_required_columns
        check_header_columns
        validate_rows
        check_constraints_for_types
        check_unique_variables
        check_values_column_position
        check_values
        @results
      end

      def rows_exist?
        result = !(@file.nil? or @file.headers.blank? or @file.data.blank?)
        @results[:errors].push("No rows containing data could be found") unless result
        result
      end

      def variable_name_column_exists?
        result = @file.headers.include?(EXPECTED_COLUMNS[0])
        @results[:errors].push("The #{EXPECTED_COLUMNS[0]} column is missing and is required") unless result
        result
      end

      def check_required_columns
        REQUIRED_DATA_COLUMNS.each_with_index do |header, index|
          found_index = @file.headers.index(header)
          result ||= !found_index.nil?
          @results[:errors].push("The #{header} column is missing and is required") if found_index.nil?
        end
      end

      def check_header_columns
        # Compare against the standard set of headers that we expect
        EXPECTED_COLUMNS.each_with_index do |header, index|
          found_index = @file.headers.index(header)
          @results[:warnings].push("The #{header} column is missing and should be included") if found_index.nil?
          @results[:warnings].push("The #{header} column is normally the #{(index + 1).ordinalize} column but in this dictionary is the #{(found_index + 1).ordinalize}") if !found_index.nil? and found_index != index
        end

        # Check for extra columns that are included
        @file.headers.each_with_index do |header, index|
          found_index = EXPECTED_COLUMNS.index(header)
          @results[:warnings].push("The #{(index + 1).ordinalize} column, #{header}, is not a standard column in data dictionaries") if found_index.nil?
        end
      end

      def validate_rows
        EXPECTED_COLUMNS.each_with_index do |header, col_index|
          found_index = @file.headers.index(header)
          next if found_index.nil? or COLUMN_VALIDATION_REGEX[col_index].nil?
          validation = COLUMN_VALIDATION_REGEX[col_index]
          @file.data.each_with_index do |row, index|
            @results[:errors].push("'#{row[0]}' (#{(index + 1).ordinalize} row), column '#{header}' (value = '#{row[found_index]}') is invalid: #{validation[1]}") unless validation[0].match(row[found_index])
          end
        end
      end

      def check_unique_variables
        @file.data.each_with_index do |row, index|
          existing_index = @variables.find_index{ |x| x.casecmp(row[0]) == 0 }
          unless existing_index.nil?
            @results[:errors].push("'#{row[0]}' (#{(index + 1).ordinalize} row) appears to be a duplicate of the variable '#{@variables[existing_index]}' (#{(existing_index + 1).ordinalize} row).")
          else
            @variables.push row[0]
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
            @results[:errors].push("The VALUES column (#{(found_index + 1).ordinalize} column) must be the last, non-empty column")
            @values_column_valid = false
            break
          end
        end
      end

      def check_constraints_for_types
        type_index = @file.headers.index("TYPE")
        return if type_index.nil?
        units_index = @file.headers.index("UNITS")
        min_index = @file.headers.index("MIN")
        max_index = @file.headers.index("MAX")
        @file.data.each_with_index do |row, index|
          next unless (row[type_index] == "Decimal" or row[type_index] == "Integer")
          @results[:errors].push("'#{row[0]}' (#{(index + 1).ordinalize} row) is missing units - this is required for variables of type '#{row[type_index]}'") unless units_index.nil? or !row[units_index].blank?
          @results[:errors].push("'#{row[0]}' (#{(index + 1).ordinalize} row) is missing a minimum value - this is required for variables of type '#{row[type_index]}'") unless min_index.nil? or !row[min_index].blank?
          @results[:errors].push("'#{row[0]}' (#{(index + 1).ordinalize} row) is missing a maximum value - this is required for variables of type '#{row[type_index]}'") unless max_index.nil? or !row[max_index].blank?
        end
      end

      def check_values
        return unless @values_column_valid
        # Based on if the values column is valid, we can assume that the VALUES columns are all at the end
        found_index = @file.headers.index("VALUES")
        @file.data.each_with_index do |row, index|
          unique_values = Hash.new
          next if row.fields[-1].blank?
          variables = row.fields[-1].split(';')
          variables.each_with_index do |variable, var_index|
            variable ||= ""
            variable_parts = variable.split('=')
            @results[:errors].push("Value '#{variable}' for variable '#{row[0]}' (#{(index + 1).ordinalize} row) is invalid.  We are expecting something that looks like 'val=Description'") unless variable_parts.length == 2
            found_item = unique_values[variable_parts[0].upcase]
            if (found_item.nil?)
              unique_values[variable_parts[0].upcase] = variable_parts
            else
              @results[:errors].push("It appears that the value '#{variable}' for variable '#{row[0]}' (#{(index + 1).ordinalize} row) is a duplicate value for this variable.")
            end
          end
        end
      end
    end
  end
end