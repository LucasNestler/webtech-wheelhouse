require_relative "api_test_case"

class ApiCorsTest < ApiTestCase
  PAGES = "https://lucasnestler.github.io".freeze
  LOCAL = "http://localhost:5500".freeze
  OTHER = "https://evil.example".freeze

  setup { @service = Service.create!(name: "Brakes", default_price: 35) }

  def preflight(path, origin, method)
    options path, headers: { "Origin" => origin, "Access-Control-Request-Method" => method }
  end

  def allowed_origin
    response.headers["Access-Control-Allow-Origin"]
  end

  test "the page's two origins can read the price list" do
    [ PAGES, LOCAL ].each do |origin|
      [ "/api/v1/services", "/api/v1/services/#{@service.id}", "/api/v1/services/999999" ].each do |path|
        get path, headers: { "Origin" => origin }
        assert_equal origin, allowed_origin, path
      end
    end
  end

  test "any other origin gets no permission" do
    get "/api/v1/services", headers: { "Origin" => OTHER }
    assert_nil allowed_origin

    get "/api/v1/services", headers: { "Origin" => "http://localhost:3000" }
    assert_nil allowed_origin

    preflight "/api/v1/services", OTHER, "GET"
    assert_nil allowed_origin
  end

  test "the routes that need the token are open to no origin" do
    preflight "/api/v1/repairs", PAGES, "GET"
    assert_nil allowed_origin

    get "/api/v1/repairs", headers: auth.merge("Origin" => PAGES)
    assert_nil allowed_origin

    preflight "/api/v1/services", PAGES, "POST"
    assert_nil allowed_origin
  end

  test "no Origin header, no CORS headers, same answer" do
    get "/api/v1/services"

    assert_json_response :ok
    assert_nil allowed_origin
  end

  test "the HTML pages are not opened" do
    get "/services", headers: { "Origin" => PAGES }
    assert_response :ok
    assert_nil allowed_origin
  end
end
