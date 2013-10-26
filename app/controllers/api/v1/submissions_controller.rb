require 'validation/file_processor'
require 'validation/data_dictionary_validator'
require 'validation/data_file_validator'
require 'json'

##
# API controller for Submissions
class Api::V1::SubmissionsController < Api::V1::ApiController
  include SubmissionsHelper

  def create
    get_data_from_params(params[:data_dictionary], params[:data_file])
    respond_to do |format|
      format.json { render :json => { :dictionary_file => @data_dictionary_results, :data_file => @data_file_results }.to_json }
      format.html { render "submissions/report"}
    end
  end

  def index
    render :layout => "application"
  end
end