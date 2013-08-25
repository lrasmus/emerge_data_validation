class Submission < ActiveRecord::Base
  attr_accessible :content_type, :data_dictionary, :data_file, :organization
end
