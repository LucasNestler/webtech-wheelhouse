require "test_helper"

class RepairTakenInTest < ActionDispatch::IntegrationTest
  setup do
    customer = Customer.create!(name: "Test", phone: "555")
    @bike = Bike.create!(make: "Giant", model: "Escape", color: "Blue", serial_number: "SN-T-1", customer: customer)
    @attributes = { bike_id: @bike.id, promised_on: Date.current + 2 }
    sign_in_as users(:one)
  end

  def count_queries
    count = 0
    counter = ->(*, payload) { count += 1 unless payload[:name].in?(%w[SCHEMA TRANSACTION]) || payload[:cached] }
    ActiveSupport::Notifications.subscribed(counter, "sql.active_record") { yield }
    count
  end

  test "the repair records the signed-in account" do
    post repair_orders_path, params: { repair_order: @attributes }

    assert_equal users(:one), RepairOrder.last.taken_in_by
  end

  test "another account's id, written by hand, is ignored" do
    post repair_orders_path, params: { repair_order: @attributes.merge(taken_in_by_id: users(:two).id) }

    assert_equal users(:one), RepairOrder.last.taken_in_by
  end

  test "the form has no field for it" do
    get new_repair_order_path

    assert_response :ok
    assert_select "[name*=taken_in_by]", count: 0
  end

  test "editing a repair does not change it" do
    repair = RepairOrder.create!(@attributes.merge(taken_in_by: users(:two)))

    patch repair_order_path(repair), params: { repair_order: { promised_on: Date.current + 5, taken_in_by_id: users(:one).id } }

    assert_equal users(:two), repair.reload.taken_in_by
    assert_equal Date.current + 5, repair.promised_on
  end

  test "an old repair stays without one when edited" do
    repair = RepairOrder.create!(@attributes)

    patch repair_order_path(repair), params: { repair_order: { promised_on: Date.current + 5 } }

    assert_nil repair.reload.taken_in_by
  end

  test "the page shows the member of the staff, the address, or that it is not recorded" do
    sam = Mechanic.create!(name: "Sam Vasquez", role: "Lead Mechanic")
    users(:two).update!(mechanic: sam)

    get repair_order_path(RepairOrder.create!(@attributes.merge(taken_in_by: users(:two))))
    assert_select "p", /Taken in by:\s+Sam Vasquez/

    users(:two).update!(mechanic: nil)
    get repair_order_path(RepairOrder.last)
    assert_select "p", /Taken in by:\s+two@example\.com/

    get repair_order_path(RepairOrder.create!(@attributes))
    assert_select "p", /Taken in by:\s+Not recorded/
  end

  test "the index and the page of a bike show it in a column of their own" do
    RepairOrder.create!(@attributes.merge(taken_in_by: users(:two)))

    [ repair_orders_path, bike_path(@bike) ].each do |path|
      get path
      assert_select "thead th", text: "Taken in by"
      assert_select "tbody td", text: "two@example.com"
      assert_equal css_select("thead th").size, css_select("tbody tr:first-child td").size
    end
  end

  test "the repairs index runs a fixed number of queries" do
    add_repairs = lambda do |prefix, count|
      count.times do |i|
        staff = Mechanic.create!(name: "#{prefix} #{i}", role: "Mechanic")
        user = User.create!(email_address: "#{prefix}#{i}@wheelhouse.cl", password: "long-enough-1", password_confirmation: "long-enough-1", mechanic: staff)
        customer = Customer.create!(name: "#{prefix} #{i}", phone: "1")
        bike = Bike.create!(make: "M", model: "X", color: "Red", serial_number: "#{prefix}-#{i}", customer: customer)
        RepairOrder.create!(bike: bike, promised_on: Date.current + 1, taken_in_by: user)
      end
    end

    add_repairs.call("a", 2)
    before = count_queries { get repair_orders_path }
    add_repairs.call("b", 8)
    after = count_queries { get repair_orders_path }

    assert_response :ok
    assert_equal before, after
  end
end
