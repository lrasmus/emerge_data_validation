require 'validation/file_processor'
require 'validation/data_dictionary_validator'
require 'validation/data_file_validator'
require 'json'

##
# API controller for Submissions
class Api::V1::SubmissionsController < Api::V1::ApiController
  include SubmissionsHelper

  def create
    get_data_from_params(params[:data_dictionary], params[:data_dictionary].original_filename,
      params[:data_file], (params[:data_file] ? params[:data_file].original_filename : nil))
    respond_to do |format|
      format.json { render :json => { :dictionary_file => @data_dictionary_results, :data_file => @data_file_results }.to_json }
      format.html { render "submissions/report"}
    end
  end

  def create_local
    dd_file = File.open(params[:data_dictionary], "r") if params[:data_dictionary]
    data_file = File.open(params[:data_file], "r") if params[:data_file]
    get_data_from_params(dd_file, params[:data_dictionary], data_file, params[:data_file])
    respond_to do |format|
      format.json { render :json => { :dictionary_file => @data_dictionary_results, :data_file => @data_file_results }.to_json }
      format.html { render "submissions/report"}
    end
  end

  def index
    render :layout => "application"
  end
end