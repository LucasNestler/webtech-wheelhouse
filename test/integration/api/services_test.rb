require_relative "api_test_case"

class ApiServicesTest < ApiTestCase
  setup do
    @brakes = Service.create!(name: "Brakes", default_price: 35)
    @tune_up = Service.create!(name: "Tune-up", default_price: 45.5)
  end

  test "the collection is public, ordered by name, with one document shape" do
    get "/api/v1/services"

    assert_json_response :ok
    assert_equal [ "Brakes", "Tune-up" ], json.map { |service| service["name"] }
    assert_equal({ "id" => @tune_up.id, "name" => "Tune-up", "price" => "45.50", "repairs_count" => 0 }, json.last)
  end

  test "one service has the same shape as the collection" do
    get "/api/v1/services"
    from_collection = json.find { |service| service["id"] == @brakes.id }

    get "/api/v1/services/#{@brakes.id}"

    assert_json_response :ok
    assert_equal from_collection, json
  end

  test "repairs_count counts repairs, not lines" do
    repair = create_repair(service: @brakes)
    repair.repair_line_items.create!(service: @brakes, charged_price: 5)
    create_repair(service: @brakes)

    get "/api/v1/services/#{@brakes.id}"
    assert_equal 2, json["repairs_count"]

    get "/api/v1/services"
    assert_equal [ 2, 0 ], json.map { |service| service["repairs_count"] }
  end

  test "an unknown id answers the error shape" do
    get "/api/v1/services/999999"
    assert_error_shape :not_found

    get "/api/v1/services/not-a-number"
    assert_error_shape :not_found

    get "/api/v1/services/99999999999999999999999"
    assert_error_shape :not_found
  end

  test "the answer is JSON whatever the Accept header says" do
    get "/api/v1/services", headers: { "Accept" => "text/html" }
    assert_json_response :ok

    get "/api/v1/services/999999", headers: { "Accept" => "text/html" }
    assert_error_shape :not_found
  end

  test "the API has no new, edit, update or destroy" do
    get "/api/v1/services/new"
    assert_error_shape :not_found

    get "/api/v1/services/#{@brakes.id}/edit"
    assert_error_shape :not_found

    delete "/api/v1/services/#{@brakes.id}", headers: auth
    assert_error_shape :not_found
    assert Service.exists?(@brakes.id)

    get "/api/v1/nothing/here"
    assert_error_shape :not_found
  end

  test "the collection runs a fixed number of queries" do
    create_repair(service: @brakes)
    before = count_queries { get "/api/v1/services" }

    5.times do |i|
      service = Service.create!(name: "Extra #{i}", default_price: 10)
      2.times { create_repair(service: service) }
    end
    after = count_queries { get "/api/v1/services" }

    assert_equal before, after
  end

  test "a GET writes nothing and leaves no session" do
    assert_no_difference [ "Service.count", "RepairLineItem.count" ] do
      get "/api/v1/services"
    end
    assert_nil response.headers["Set-Cookie"]
  end

  test "creating answers 201 with the document and its Location" do
    assert_difference -> { Service.count }, 1 do
      post "/api/v1/services", params: { service: { name: "Wash", default_price: "12.5" } }, headers: auth, as: :json
    end

    assert_json_response :created
    created = Service.find_by!(name: "Wash")
    assert_equal({ "id" => created.id, "name" => "Wash", "price" => "12.50", "repairs_count" => 0 }, json)
    assert_equal "http://www.example.com/api/v1/services/#{created.id}", response.headers["Location"]
  end

  test "creating does not ask for a CSRF token" do
    ActionController::Base.allow_forgery_protection = true
    post "/api/v1/services", params: { service: { name: "Wash", default_price: 12 } }, headers: auth, as: :json
    assert_json_response :created
  ensure
    ActionController::Base.allow_forgery_protection = false
  end

  test "attributes that are not on the list are dropped" do
    post "/api/v1/services",
      params: { service: { name: "Wash", default_price: 12, active: false, id: 4242, created_at: "2001-01-01" } },
      headers: auth, as: :json

    assert_json_response :created
    created = Service.find_by!(name: "Wash")
    assert created.active
    assert_not_equal 4242, created.id
    assert_not_equal 2001, created.created_at.year
  end

  test "a refused service answers 422 with the sentences of the form" do
    post "/api/v1/services", params: { service: { name: "Brakes", default_price: -1 } }, headers: auth, as: :json

    assert_error_shape :unprocessable_entity
    expected = Service.new(name: "Brakes", default_price: -1).tap(&:validate).errors.full_messages
    assert_equal expected, json["errors"]
  end

  test "a price the column cannot hold is refused, not a 500" do
    assert_no_difference -> { Service.count } do
      post "/api/v1/services", params: { service: { name: "Gold", default_price: 99_999_999 } }, headers: auth, as: :json
    end

    assert_error_shape :unprocessable_entity
  end

  test "bodies with nothing to read answer 400" do
    bodies = [ "", "{}", "[]", "null", "42", "not json", "{bad", '{"service":{}}', '{"service":"x"}', '{"colour":"red"}' ]

    bodies.each do |body|
      assert_no_difference -> { Service.count }, "body: #{body.inspect}" do
        post "/api/v1/services", params: body, headers: auth.merge("Content-Type" => "application/json")
      end
      assert_error_shape :bad_request
    end
  end

  test "text the API cannot read answers 400 in the error shape" do
    headers = auth.merge("Content-Type" => "application/json")

    assert_no_difference -> { Service.count } do
      post "/api/v1/services", params: '{"service":{"name":"a\u0000b","default_price":5}}', headers: headers
      assert_error_shape :bad_request

      post "/api/v1/services", params: "{\"service\":{\"name\":\"\xE0\",\"default_price\":5}}".b, headers: headers
      assert_error_shape :bad_request
    end

    get "/api/v1/services/%E0"
    assert_error_shape :bad_request
  end

  test "a body that is not JSON answers 400" do
    post "/api/v1/services", headers: auth
    assert_error_shape :bad_request
  end

  test "creating without the right token answers 401 before anything else" do
    assert_no_difference -> { Service.count } do
      post "/api/v1/services", params: { service: { name: "Wash", default_price: 12 } }, as: :json
    end
    assert_error_shape :unauthorized

    post "/api/v1/services", params: "not json", headers: { "Content-Type" => "application/json" }
    assert_error_shape :unauthorized
  end
end
