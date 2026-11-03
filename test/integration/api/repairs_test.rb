require_relative "api_test_case"

class ApiRepairsTest < ApiTestCase
  setup do
    @service = Service.create!(name: "Brakes", default_price: 35)
  end

  test "the document carries what accounting needs and nothing else" do
    repair = create_repair(state: :picked_up, service: @service, price: 30.5,
      created_at: 10.days.ago, promised_on: 5.days.ago, picked_up_at: 1.day.ago)
    repair.repair_line_items.create!(service: @service, charged_price: 10)
    bike = repair.bike

    get "/api/v1/repairs/#{repair.id}", headers: auth

    assert_json_response :ok
    assert_equal({
      "id" => repair.id,
      "state" => "picked_up",
      "came_in_on" => repair.created_at.to_date.iso8601,
      "promised_on" => repair.promised_on.iso8601,
      "picked_up_on" => repair.picked_up_at.to_date.iso8601,
      "bike" => { "brand" => "Giant", "model" => "Escape", "serial_number" => bike.serial_number },
      "customer" => { "name" => bike.customer.name },
      "lines" => [
        { "service" => "Brakes", "price" => "30.50" },
        { "service" => "Brakes", "price" => "10.00" }
      ],
      "total" => "40.50",
      "overdue" => false,
      "customer_answer" => "approved"
    }, json)
    assert_not_includes response.body, bike.customer.phone
    assert_no_match(/_id"/, response.body)
  end

  test "a repair with no lines, not handed back, totals zero" do
    repair = create_repair

    get "/api/v1/repairs/#{repair.id}", headers: auth

    assert_nil json["picked_up_on"]
    assert_equal [], json["lines"]
    assert_equal "0.00", json["total"]
  end

  test "overdue and the customer's answer follow the repair" do
    late = create_repair(state: :awaiting_estimate_approval, quote_accepted: nil, created_at: 10.days.ago, promised_on: 1.day.ago)
    declined = create_repair(state: :ready_for_pickup, quote_accepted: false)

    get "/api/v1/repairs/#{late.id}", headers: auth
    assert_equal true, json["overdue"]
    assert_equal "pending", json["customer_answer"]

    get "/api/v1/repairs/#{declined.id}", headers: auth
    assert_equal false, json["overdue"]
    assert_equal "rejected", json["customer_answer"]
  end

  test "the collection is a list ordered by the promised date, same shape as one repair" do
    later = create_repair(promised_on: Date.current + 9)
    sooner = create_repair(promised_on: Date.current + 1)

    get "/api/v1/repairs", headers: auth

    assert_json_response :ok
    assert_equal [ sooner.id, later.id ], json.map { |repair| repair["id"] }
    collection_entry = json.first

    get "/api/v1/repairs/#{sooner.id}", headers: auth
    assert_equal json, collection_entry
  end

  test "the filter answers only the repairs in that state" do
    waiting = create_repair(state: :dropped_off)
    create_repair(state: :in_progress)

    get "/api/v1/repairs", params: { state: "dropped_off" }, headers: auth

    assert_json_response :ok
    assert_equal [ waiting.id ], json.map { |repair| repair["id"] }
  end

  test "every state of the enum is accepted by the filter" do
    RepairOrder.statuses.each_key do |state|
      get "/api/v1/repairs", params: { state: state }, headers: auth
      assert_json_response :ok
    end
  end

  test "a value that is not a state answers 400 listing the states" do
    [ { state: "lost" }, { state: "" }, { state: "Picked Up" }, { state: [ "picked_up" ] }, { state: { a: "b" } } ].each do |query|
      get "/api/v1/repairs", params: query, headers: auth

      assert_error_shape :bad_request
      RepairOrder.statuses.each_key { |state| assert_includes json["errors"].join, state }
    end
  end

  test "a state in an invalid encoding answers 400 in the error shape" do
    get "/api/v1/repairs?state=%E0", headers: auth
    assert_error_shape :bad_request
  end

  test "an odd Authorization header answers 401" do
    [ "Bearer \xC3\xA9", "Basic abc", "Bearer", "" ].each do |value|
      get "/api/v1/repairs", headers: { "Authorization" => value }
      assert_error_shape :unauthorized
    end
  end

  test "an unknown repair answers 404" do
    get "/api/v1/repairs/999999", headers: auth
    assert_error_shape :not_found
  end

  test "reading repairs needs the token" do
    repair = create_repair

    [ "/api/v1/repairs", "/api/v1/repairs/#{repair.id}", "/api/v1/repairs/999999" ].each do |path|
      get path
      assert_error_shape :unauthorized

      get path, headers: { "Authorization" => "Bearer wrong" }
      assert_error_shape :unauthorized
    end
  end

  test "a token in the query string or the body does not count" do
    get "/api/v1/repairs", params: { token: TOKEN, access_token: TOKEN }
    assert_error_shape :unauthorized
  end

  test "no configured token means nobody gets in, without a 500" do
    configure_api_token(nil)

    get "/api/v1/repairs", headers: auth
    assert_error_shape :unauthorized

    get "/api/v1/repairs", headers: { "Authorization" => "Bearer " }
    assert_error_shape :unauthorized
  end

  test "the collection runs a fixed number of queries" do
    create_repair(service: @service)
    before = count_queries { get "/api/v1/repairs", headers: auth }

    8.times do |i|
      service = Service.create!(name: "Extra #{i}", default_price: 10)
      repair = create_repair(service: service)
      repair.repair_line_items.create!(service: @service, charged_price: 3)
    end
    after = count_queries { get "/api/v1/repairs", headers: auth }

    assert_equal before, after
  end
end
