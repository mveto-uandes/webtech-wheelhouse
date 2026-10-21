# Every controller of the API inherits from this one. It answers only JSON,
# never asks for a CSRF token and never touches the session: ActionController::API
# leaves all of that out. Every error leaves through render_errors, so a client
# always gets { "errors": [...] }.
class Api::V1::BaseController < ActionController::API
  include ActionController::HttpAuthentication::Token::ControllerMethods

  # Every route needs the token unless its controller says otherwise.
  before_action :authenticate!
  skip_before_action :authenticate!, only: :route_not_found

  rescue_from ActiveRecord::RecordNotFound do |error|
    render_errors [ "There's no #{error.model.underscore.humanize(capitalize: false)} with id #{error.id}." ], :not_found
  end

  # A request the API can't read: a filter with a value that doesn't exist.
  rescue_from ActionController::BadRequest do |error|
    render_errors [ error.message ], :bad_request
  end

  rescue_from ActionController::ParameterMissing do |error|
    render_errors [ "The body has no #{error.param} to read. Send it as JSON, for example {\"#{error.param}\": {...}}." ], :bad_request
  end

  # Raised when the parameters are first read and the body isn't JSON.
  rescue_from ActionDispatch::Http::Parameters::ParseError do
    render_errors [ "The body isn't valid JSON." ], :bad_request
  end

  # Any path under /api/v1 that no route matches lands here, so it also answers
  # JSON instead of the HTML page.
  def route_not_found
    render_errors [ "There's no #{request.method} #{request.path} in this API." ], :not_found
  end

  private

  def authenticate!
    authorized = authenticate_with_http_token do |token, _options|
      expected = Rails.application.credentials.api_token
      expected.present? && ActiveSupport::SecurityUtils.secure_compare(token, expected)
    end
    return if authorized

    response.headers["WWW-Authenticate"] = 'Bearer realm="Wheelhouse"'
    render_errors [ "This route needs a valid token in the Authorization header: Bearer <token>." ], :unauthorized
  end

  def render_errors(messages, status)
    render json: { errors: messages }, status: status
  end

  # Prices travel as strings with two decimals ("45000.00"), the same digits
  # the decimal column holds. A JSON number would become a float on the way.
  def money(amount)
    ActiveSupport::NumberHelper.number_to_rounded(amount, precision: 2)
  end
end
