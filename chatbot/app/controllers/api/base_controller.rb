module Api
  class BaseController < ActionController::API
    rescue_from ActionController::ParameterMissing do |e|
      render json: { error: "missing_parameter", detail: e.param.to_s }, status: :bad_request
    end
  end
end
