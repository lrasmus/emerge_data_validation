require 'validation/file_processor'
require 'validation/data_dictionary_validator'
require 'validation/data_file_validator'

class SubmissionsController < ApplicationController
  # GET /submissions
  # GET /submissions.json
  def index
    @submissions = Submission.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @submissions }
    end
  end

  # GET /submissions/1
  # GET /submissions/1.json
  def show
    @submission = Submission.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @submission }
    end
  end

  # GET /submissions/new
  # GET /submissions/new.json
  def new
    @submission = Submission.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @submission }
    end
  end

  # GET /submissions/1/edit
  def edit
    @submission = Submission.find(params[:id])
  end

  # POST /submissions
  # POST /submissions.json
  def create
    @submission = Submission.new(params[:submission])
    data_dictionary = params[:submission][:data_dictionary].read
    data_file = params[:submission][:data_file].read unless params[:submission][:data_file].blank?

    unless data_dictionary.blank?
      dd_processor = EMERGE::Phenotype::DataDictionaryValidator.new data_dictionary, :csv
      @data_dictionary_results = dd_processor.validate
      @data_dictionary_results[:file_name] = params[:submission][:data_dictionary].original_filename
      unless data_file.blank?
        df_processor = EMERGE::Phenotype::DataFileValidator.new data_file, dd_processor.variables, :csv
        @data_file_results = df_processor.validate
        @data_file_results[:file_name] = params[:submission][:data_file].original_filename
      end
    end

    render "report"

    #respond_to do |format|
    #  if @submission.save
    #    format.html { redirect_to @submission, notice: 'Submission was successfully created.' }
    #    format.json { render json: @submission, status: :created, location: @submission }
    #  else
    #    format.html { render action: "new" }
    #    format.json { render json: @submission.errors, status: :unprocessable_entity }
    #  end
    #end
  end

  # PUT /submissions/1
  # PUT /submissions/1.json
  def update
    @submission = Submission.find(params[:id])

    respond_to do |format|
      if @submission.update_attributes(params[:submission])
        format.html { redirect_to @submission, notice: 'Submission was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @submission.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /submissions/1
  # DELETE /submissions/1.json
  def destroy
    @submission = Submission.find(params[:id])
    @submission.destroy

    respond_to do |format|
      format.html { redirect_to submissions_url }
      format.json { head :no_content }
    end
  end
end
