require 'csv'

module EMERGE
  module Phenotype
    # Takes the contents of a data file and processes it to determine header information and data
    #
    # Author::    Luke Rasmussen (mailto:luke.rasmussen@northwestern.edu)
    class FileProcessor
      def initialize(file_content, data_type, delimiter = :csv)
        # Force the file text to end up as UTF-8.  There are issues with some real files unless we explicitly do this
        # The first encode to UTF-16 helps to ensure the encoding is switched & replace is done
        @file_content = file_content.encode('UTF-16', :invalid => :replace, :undef => :replace, :replace => "").encode('UTF-8') unless file_content.nil?
        @data_type = data_type
        @delimiter = delimiter
        @headers = []
        @rows_exist = false
        process
      end

      def headers
        @headers
      end

      def file_content
        return @file_content
      end

      def rows_exist?
        @rows_exist
      end

      # Take the data for this file and perform basic cleaning and normalization so that a header and data
      # rows are accessible.
      def process
        lines = clean_lines

        # Peek ahead to get the headers
        unless @file_content.blank?
          CSV.parse(@file_content, {:headers => true, :skip_blanks => true}) do |row|
            @rows_exist = true
            @headers = row.headers
            break
          end
        end

        @rows_exist = @rows_exist and !@headers.blank?
      end

      # Perform cleaning and normalization on the input lines
      #  - Remove lines that have a # as the first non-whitespace character (means it's a comment)
      def clean_lines
        lines = @file_content.split("\r").select { |line| !line.match(/$\s*#/)} unless @file_content.nil?
      end
    end
  end
end