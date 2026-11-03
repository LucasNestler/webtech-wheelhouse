module Api
  module V1
    class BaseController < ActionController::API
      include ActionController::HttpAuthentication::Token::ControllerMethods

      # Every route needs the token unless its controller says otherwise.
      before_action :require_token

      rescue_from ActiveRecord::RecordNotFound do
        render_errors [ "There is no record with id #{params[:id]}." ], :not_found
      end

      rescue_from ActionController::ParameterMissing,
                  ActionController::BadRequest,
                  ActionDispatch::Http::Parameters::ParseError do
        render_errors [ "The request carries nothing the API can read." ], :bad_request
      end

      # Anything under /api/v1 that has no route still answers JSON.
      skip_before_action :require_token, only: :route_not_found

      def route_not_found
        render_errors [ "There is no such route in the API." ], :not_found
      end

      private

      def require_token
        return if authenticate_with_http_token { |token, _options| valid_token?(token) }

        response.headers["WWW-Authenticate"] = "Bearer"
        render_errors [ "A valid token is required in the Authorization header." ], :unauthorized
      end

      def valid_token?(token)
        expected = Rails.application.credentials.api_token.to_s
        expected.present? && ActiveSupport::SecurityUtils.secure_compare(token, expected)
      end

      def render_errors(messages, status)
        render json: { errors: messages }, status: status
      end

      # Prices travel as strings with two decimals (see docs/api.md).
      def money(amount)
        format("%.2f", amount)
      end
    end
  end
end
