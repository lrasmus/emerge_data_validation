##
# Base controller for all /api/ requests
class Api::V1::ApiController < ActionController::Base
  # All API endpoints respond to JSON.
  respond_to :json
end