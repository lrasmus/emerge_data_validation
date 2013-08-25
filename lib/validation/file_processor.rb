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
        @file_content = file_content.encode('UTF-16', :invalid => :replace, :undef => :replace, :replace => "").encode('UTF-8')
        @data_type = data_type
        @delimiter = delimiter
        process
      end

      def headers
        @data.headers
      end

      def data
        @data
      end

      # Take the data for this file and perform basic cleaning and normalization so that a header and data
      # rows are accessible.
      def process
        lines = clean_lines
        @data = CSV.parse(lines.join("\r"), {:headers => true, :skip_blanks => true})
        #@data.delete(nil) # Nil columns should be purged
      end

      # Perform cleaning and normalization on the input lines
      #  - Remove lines that have a # as the first non-whitespace character (means it's a comment)
      def clean_lines
        lines = @file_content.split("\r").select { |line| !line.match(/$\s*#/)}
      end
    end
  end
end