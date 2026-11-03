# Text in an invalid encoding is refused while Rails reads the path or the
# parameters, before the base controller's rescue_from can see it. Without this
# the API would answer those requests with the HTML page for a 400.
class ApiMalformedRequests
  BODY = { errors: [ "The request carries nothing the API can read." ] }.to_json.freeze

  def initialize(app)
    @app = app
  end

  def call(env)
    @app.call(env)
  rescue ActionController::BadRequest
    raise unless env["PATH_INFO"].match?(%r{\A/api(/|\z)})

    [ 400, { "content-type" => "application/json; charset=utf-8" }, [ BODY ] ]
  end
end

Rails.application.config.middleware.use ApiMalformedRequests
