require "test_helper"

# Shared by the API's tests. A fresh clone has no master key, so the token the
# tests use is set here and never depends on the encrypted credentials.
class ApiTestCase < ActionDispatch::IntegrationTest
  TOKEN = "test-api-token".freeze

  setup { configure_api_token(TOKEN) }
  teardown { Rails.application.credentials.singleton_class.send(:remove_method, :api_token) }

  private

  def configure_api_token(value)
    Rails.application.credentials.define_singleton_method(:api_token) { value }
  end

  def auth
    { "Authorization" => "Bearer #{TOKEN}" }
  end

  def json
    JSON.parse(response.body)
  end

  def assert_json_response(status)
    assert_response status
    assert_equal "application/json", response.media_type
  end

  def assert_error_shape(status)
    assert_json_response status
    assert_equal [ "errors" ], json.keys
    assert_kind_of Array, json["errors"]
    assert json["errors"].any?
    assert json["errors"].all?(String)
  end

  def count_queries
    count = 0
    counter = ->(*, payload) { count += 1 unless payload[:name].in?(%w[SCHEMA TRANSACTION]) || payload[:cached] }
    ActiveSupport::Notifications.subscribed(counter, "sql.active_record") { yield }
    count
  end

  def create_repair(state: :dropped_off, service: nil, price: 10, **attrs)
    @sequence = @sequence.to_i + 1
    customer = Customer.create!(name: "Customer #{@sequence}", phone: "555-#{@sequence}")
    bike = Bike.create!(make: "Giant", model: "Escape", color: "Blue", serial_number: "SN-#{@sequence}", customer: customer)
    repair = RepairOrder.create!({ bike: bike, promised_on: Date.current + 2, status: state, quote_accepted: true }.merge(attrs))
    repair.repair_line_items.create!(service: service, charged_price: price) if service
    repair
  end
end
