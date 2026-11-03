require "test_helper"

class AuthorizationTest < ActionDispatch::IntegrationTest
  setup do
    @sam = Mechanic.create!(name: "Sam Vasquez", role: "Lead Mechanic")
    @alex = Mechanic.create!(name: "Alex Chen", role: "Junior Mechanic")

    @owner = users(:one)
    @nobody = users(:two) # the default role, with no member of the staff
    @counter = account("counter@wheelhouse.cl", role: :counter)
    @sam_account = account("sam@wheelhouse.cl", role: :mechanic, mechanic: @sam)

    @customer = Customer.create!(name: "Test Customer", phone: "555-0100")
    @bike = Bike.create!(make: "Giant", model: "Escape", color: "Blue", serial_number: "SN-T-1", customer: @customer)
    @service = Service.create!(name: "Brakes", default_price: 35)

    @sam_open = repair(mechanic: @sam, status: :in_progress, quote_accepted: true)
    @sam_done = repair(mechanic: @sam, status: :picked_up, quote_accepted: true)
    @alex_open = repair(mechanic: @alex, status: :in_progress, quote_accepted: true)
    @unassigned = repair
  end

  def account(email, **attributes)
    User.create!(email_address: email, password: TEST_PASSWORD, password_confirmation: TEST_PASSWORD, **attributes)
  end

  def repair(**attributes)
    RepairOrder.create!({ bike: @bike, promised_on: Date.current + 3 }.merge(attributes))
  end

  def assert_forbidden
    assert_response :forbidden
    assert_select "nav.navbar"
    assert_select "h1", /not allowed/
  end

  def listed_repair_ids
    css_select("tbody tr td:first-child a").map { |link| link["href"][%r{/repairs/(\d+)}, 1].to_i }.sort
  end

  def count_queries
    count = 0
    counter = ->(*, payload) { count += 1 unless payload[:name].in?(%w[SCHEMA TRANSACTION]) || payload[:cached] }
    ActiveSupport::Notifications.subscribed(counter, "sql.active_record") { yield }
    count
  end

  # -- Refused requests ------------------------------------------------------

  test "a refused page is a 403 in the layout" do
    sign_in_as @sam_account

    [ customers_path, customer_path(@customer), new_customer_path, bikes_path, bike_path(@bike), new_bike_path,
      new_repair_order_path, new_service_path, edit_service_path(@service), new_mechanic_path, edit_mechanic_path(@sam) ].each do |path|
      get path
      assert_forbidden
    end
  end

  test "a refused request in another format still gets the page, not an error" do
    sign_in_as @sam_account

    get customers_path(format: :json)
    assert_response :forbidden
  end

  test "refused writes change nothing" do
    sign_in_as @counter

    delete customer_path(@customer)
    assert_forbidden
    assert Customer.exists?(@customer.id)

    delete bike_path(@bike)
    assert_forbidden
    assert Bike.exists?(@bike.id)

    delete repair_order_path(@sam_open)
    assert_forbidden
    assert RepairOrder.exists?(@sam_open.id)

    patch service_path(@service), params: { service: { name: "Changed" } }
    assert_forbidden
    assert_equal "Brakes", @service.reload.name

    delete service_path(@service)
    assert_forbidden
    assert Service.exists?(@service.id)

    assert_no_difference -> { Mechanic.count } do
      post mechanics_path, params: { mechanic: { name: "New", role: "Mechanic" } }
    end
    assert_forbidden

    patch repair_order_path(@sam_done), params: { repair_order: { promised_on: Date.current + 9 } }
    assert_forbidden
    assert_not_equal Date.current + 9, @sam_done.reload.promised_on
  end

  test "a request that is also malformed is refused before it is read" do
    sign_in_as @sam_account

    post customers_path
    assert_forbidden
  end

  test "a visitor is sent to sign in and never sees the 403 page" do
    [ customers_path, new_service_path, edit_service_path(@service), repair_order_path(@sam_open) ].each do |path|
      get path
      assert_redirected_to new_session_path
    end

    delete service_path(@service)
    assert_redirected_to new_session_path
    assert Service.exists?(@service.id)
  end

  # -- A mechanic and the repairs --------------------------------------------

  test "the index of a mechanic has their repairs, and the owner and counter have all" do
    all_ids = [ @sam_open, @sam_done, @alex_open, @unassigned ].map(&:id).sort

    sign_in_as @sam_account
    get repair_orders_path
    assert_equal [ @sam_open.id, @sam_done.id ].sort, listed_repair_ids
    delete session_path

    [ @owner, @counter ].each do |user|
      sign_in_as user
      get repair_orders_path
      assert_equal all_ids, listed_repair_ids
      delete session_path
    end
  end

  test "the filters and the overdue view are chained on the scope" do
    late_sam = repair(mechanic: @sam, created_at: 5.days.ago, promised_on: 1.day.ago)
    repair(mechanic: @alex, created_at: 5.days.ago, promised_on: 1.day.ago)
    sign_in_as @sam_account

    get repair_orders_path(state: "in_progress")
    assert_equal [ @sam_open.id ], listed_repair_ids

    get repair_orders_path(overdue: 1)
    assert_equal [ late_sam.id ], listed_repair_ids

    get repair_orders_path(state: "not-a-state")
    assert_response :ok
    assert_includes listed_repair_ids, @sam_open.id
    assert_not_includes listed_repair_ids, @alex_open.id
  end

  test "the owner can filter too" do
    sign_in_as @owner

    get repair_orders_path(state: "picked_up")
    assert_equal [ @sam_done.id ], listed_repair_ids
    assert_select "a.btn-primary", text: "Picked Up"
  end

  test "another mechanic's repair answers 403, on its page, its form and its writes" do
    sign_in_as @sam_account

    get repair_order_path(@alex_open)
    assert_forbidden

    get edit_repair_order_path(@alex_open)
    assert_forbidden

    patch repair_order_path(@alex_open), params: { repair_order: { status: "ready_for_pickup" } }
    assert_forbidden
    assert @alex_open.reload.in_progress?

    get repair_order_path(@unassigned)
    assert_forbidden
  end

  test "the scope and the page give the same answer for every role and repair" do
    [ @owner, @counter, @sam_account, @nobody ].each do |user|
      sign_in_as user
      get repair_orders_path
      listed = listed_repair_ids

      [ @sam_open, @sam_done, @alex_open, @unassigned ].each do |record|
        get repair_order_path(record)
        assert_response(listed.include?(record.id) ? :ok : :forbidden, "#{user.email_address} on repair #{record.id}")
      end
      delete session_path
    end
  end

  test "the default account reads no repairs, not even unassigned ones" do
    sign_in_as @nobody

    get repair_orders_path
    assert_response :ok
    assert_empty listed_repair_ids

    get repair_order_path(@unassigned)
    assert_forbidden

    get services_path
    assert_response :ok
    get mechanics_path
    assert_response :ok
    get customers_path
    assert_forbidden
  end

  test "handed back: only the owner edits it" do
    [ @sam_account, @counter ].each do |user|
      sign_in_as user
      get repair_order_path(@sam_done)
      assert_response :ok
      assert_select "a[href=?]", edit_repair_order_path(@sam_done), count: 0

      get edit_repair_order_path(@sam_done)
      assert_forbidden
      delete session_path
    end

    sign_in_as @owner
    get edit_repair_order_path(@sam_done)
    assert_response :ok
  end

  # -- The fields each role writes -------------------------------------------

  test "a mechanic changes the state and the diagnosis of their repair" do
    sign_in_as @sam_account

    patch repair_order_path(@sam_open), params: { repair_order: { status: "ready_for_pickup", diagnosis: "Worn chain" } }

    assert_redirected_to repair_order_path(@sam_open)
    assert @sam_open.reload.ready_for_pickup?
    assert_includes @sam_open.diagnosis.to_plain_text, "Worn chain"
  end

  test "a mechanic adds photos" do
    sign_in_as @sam_account
    photo = Rack::Test::UploadedFile.new(Rails.root.join("db/seeds/black_bike.png"), "image/png")

    patch repair_order_path(@sam_open), params: { repair_order: { intake_photos: [ photo ] } }

    assert_equal 1, @sam_open.reload.intake_photos.count
  end

  test "fields outside a mechanic's list are dropped and the request goes on" do
    line = @sam_open.repair_line_items.create!(service: @service, charged_price: 50)
    promised = @sam_open.promised_on
    sign_in_as @sam_account

    assert_no_difference -> { RepairLineItem.count } do
      patch repair_order_path(@sam_open), params: { repair_order: {
        status: "ready_for_pickup", mechanic_id: @alex.id, bike_id: Bike.create!(make: "A", model: "B", color: "C", serial_number: "OTHER", customer: @customer).id,
        promised_on: Date.current + 30, quote_accepted: false, taken_in_by_id: @owner.id,
        repair_line_items_attributes: { "0" => { id: line.id, charged_price: 1 }, "1" => { service_id: @service.id, charged_price: 1 } }
      } }
    end

    assert_redirected_to repair_order_path(@sam_open)
    @sam_open.reload
    assert @sam_open.ready_for_pickup?
    assert_equal @sam, @sam_open.mechanic
    assert_equal @bike, @sam_open.bike
    assert_equal promised, @sam_open.promised_on
    assert_equal true, @sam_open.quote_accepted
    assert_nil @sam_open.taken_in_by
    assert_equal 50, line.reload.charged_price
  end

  test "a request with nothing but forbidden fields also goes on, unchanged" do
    sign_in_as @sam_account

    patch repair_order_path(@sam_open), params: { repair_order: { mechanic_id: @alex.id } }

    assert_redirected_to repair_order_path(@sam_open)
    assert_equal @sam, @sam_open.reload.mechanic
  end

  test "the form shows a mechanic only their fields" do
    sign_in_as @sam_account
    get edit_repair_order_path(@sam_open)

    assert_response :ok
    assert_select "[name='repair_order[status]']"
    assert_select "[name='repair_order[diagnosis]']"
    assert_select "[name='repair_order[intake_photos][]']"
    %w[ bike_id mechanic_id promised_on quote_accepted quoted_at completed_at picked_up_at ].each do |field|
      assert_select "[name='repair_order[#{field}]']", count: 0
    end
    assert_select "[name*=repair_line_items_attributes]", count: 0
    assert_no_match(/Services Charged/, response.body)
  end

  test "the owner and the counter see and write every field" do
    [ @owner, @counter ].each do |user|
      sign_in_as user
      get edit_repair_order_path(@unassigned)

      %w[ bike_id mechanic_id status promised_on quote_accepted quoted_at completed_at picked_up_at ].each do |field|
        assert_select "[name='repair_order[#{field}]']"
      end
      assert_select "[name*=repair_line_items_attributes]"

      patch repair_order_path(@unassigned), params: { repair_order: {
        mechanic_id: @alex.id, repair_line_items_attributes: { "0" => { service_id: @service.id, charged_price: 12 } }
      } }
      assert_redirected_to repair_order_path(@unassigned)
      assert_equal @alex, @unassigned.reload.mechanic
      assert_equal 12, @unassigned.repair_line_items.last.charged_price
      @unassigned.repair_line_items.destroy_all
      delete session_path
    end
  end

  test "taking in: the counter yes, and it is read from the session" do
    sign_in_as @counter

    post repair_orders_path, params: { repair_order: { bike_id: @bike.id, promised_on: Date.current + 2, taken_in_by_id: @owner.id } }

    assert_equal @counter, RepairOrder.last.taken_in_by
  end

  test "taking in: a mechanic no" do
    sign_in_as @sam_account

    assert_no_difference -> { RepairOrder.count } do
      post repair_orders_path, params: { repair_order: { bike_id: @bike.id, promised_on: Date.current + 2 } }
    end
    assert_forbidden
  end

  # -- Removing photos -------------------------------------------------------

  test "a mechanic cannot remove a photo and sees no button" do
    @sam_open.intake_photos.attach(io: Rails.root.join("db/seeds/black_bike.png").open, filename: "b.png", content_type: "image/png")
    photo = @sam_open.intake_photos.first
    sign_in_as @sam_account

    get repair_order_path(@sam_open)
    assert_select "form[action=?]", repair_order_intake_photo_path(@sam_open, photo), count: 0

    delete repair_order_intake_photo_path(@sam_open, photo)
    assert_forbidden
    assert_equal 1, @sam_open.reload.intake_photos.count
  end

  test "the counter removes a photo, except from a repair handed back" do
    [ @sam_open, @sam_done ].each do |record|
      record.intake_photos.attach(io: Rails.root.join("db/seeds/black_bike.png").open, filename: "b.png", content_type: "image/png")
    end
    sign_in_as @counter

    delete repair_order_intake_photo_path(@sam_done, @sam_done.intake_photos.first)
    assert_forbidden
    assert_equal 1, @sam_done.reload.intake_photos.count

    delete repair_order_intake_photo_path(@sam_open, @sam_open.intake_photos.first)
    assert_response :see_other
    assert_equal 0, @sam_open.reload.intake_photos.count
  end

  # -- The views follow the policies -----------------------------------------

  test "the navigation bar links only to what the role may open" do
    expected = {
      @owner => [ customers_path, bikes_path, repair_orders_path, services_path, mechanics_path ],
      @counter => [ customers_path, bikes_path, repair_orders_path, services_path, mechanics_path ],
      @sam_account => [ repair_orders_path, services_path, mechanics_path ],
      @nobody => [ repair_orders_path, services_path, mechanics_path ]
    }
    closed = [ customers_path, bikes_path ]

    expected.each do |user, links|
      sign_in_as user
      get root_path
      links.each { |path| assert_select "nav.navbar a[href=?]", path }
      (closed - links).each { |path| assert_select "nav.navbar a[href=?]", path, count: 0 }
      delete session_path
    end
  end

  test "the page of a repair shows the bike and the customer, as links only for who may open them" do
    sign_in_as @sam_account
    get repair_order_path(@sam_open)
    assert_match @bike.serial_number, response.body
    assert_match @customer.name, response.body
    assert_select "a[href=?]", bike_path(@bike), count: 0
    assert_select "a[href=?]", customer_path(@customer), count: 0
    get repair_orders_path
    assert_select "a[href=?]", bike_path(@bike), count: 0
    assert_select "a[href=?]", customer_path(@customer), count: 0
    delete session_path

    sign_in_as @counter
    get repair_order_path(@sam_open)
    assert_select "a[href=?]", bike_path(@bike)
    assert_select "a[href=?]", customer_path(@customer)
  end

  test "buttons and links only appear for who may use them" do
    sign_in_as @sam_account
    get repair_orders_path
    assert_select "a[href=?]", new_repair_order_path, count: 0
    get repair_order_path(@sam_open)
    assert_select "a[href=?]", edit_repair_order_path(@sam_open)
    assert_select "form[action=?]", repair_order_path(@sam_open), count: 0
    get services_path
    assert_select "a[href=?]", new_service_path, count: 0
    get service_path(@service)
    assert_select "a[href=?]", edit_service_path(@service), count: 0
    get mechanics_path
    assert_select "a[href=?]", new_mechanic_path, count: 0
    get mechanic_path(@sam)
    assert_select "a[href=?]", edit_mechanic_path(@sam), count: 0
    delete session_path

    sign_in_as @counter
    get repair_order_path(@sam_open)
    assert_select "a[href=?]", edit_repair_order_path(@sam_open)
    assert_select "form[action=?]", repair_order_path(@sam_open), count: 0
    get customer_path(@customer)
    assert_select "a[href=?]", edit_customer_path(@customer)
    assert_select "form[action=?]", customer_path(@customer), count: 0
    assert_select "a[href=?]", new_bike_path(customer_id: @customer.id)
    get bike_path(@bike)
    assert_select "form[action=?]", bike_path(@bike), count: 0
    delete session_path

    sign_in_as @owner
    get service_path(@service)
    assert_select "a[href=?]", edit_service_path(@service)
    assert_select "form[action=?]", service_path(@service)
    get repair_order_path(@sam_done)
    assert_select "a[href=?]", edit_repair_order_path(@sam_done)
    assert_select "form[action=?]", repair_order_path(@sam_done)
  end

  test "the owner keeps the buttons on the public price list" do
    sign_in_as @owner

    get services_path
    assert_select "a[href=?]", new_service_path
  end

  test "no view checks a role" do
    Rails.root.glob("app/views/**/*.erb").each do |file|
      assert_no_match(/role_(owner|mechanic|counter)\?/, file.read, file.to_s)
    end
  end

  # -- No action is left unchecked -------------------------------------------

  class ForgetfulController < ApplicationController
    allow_unauthenticated_access

    def index
      authorize Service
      render plain: "not built from a scope"
    end

    def show
      render plain: "never asked the policy"
    end
  end

  test "an action that forgets the policy fails, and so does an index with no scope" do
    with_routing do |set|
      set.draw do
        get "/forgetful", to: "authorization_test/forgetful#index"
        get "/forgetful/:id", to: "authorization_test/forgetful#show"
      end

      assert_raises(Pundit::AuthorizationNotPerformedError) { get "/forgetful/1" }
      assert_raises(Pundit::PolicyScopingNotPerformedError) { get "/forgetful" }
    end
  end

  test "the only controllers that skip the check are the ones in the decisions document" do
    Rails.application.eager_load!
    skipping = ApplicationController.descendants.reject { |controller| controller.name.start_with?("AuthorizationTest") }.select do |controller|
      controller._process_action_callbacks.none? { |callback| callback.filter == :verify_authorized }
    end

    assert_equal %w[ PasswordsController RegistrationsController SessionsController ], skipping.map(&:name).sort
    decisions = Rails.root.join("docs/decisions.md").read
    skipping.each { |controller| assert_includes decisions, controller.name }
  end

  test "signing in, out, up and the pages of a forgotten password keep working" do
    get new_session_path
    assert_response :ok
    get new_registration_path
    assert_response :ok
    get new_password_path
    assert_response :ok

    post passwords_path, params: { email_address: @sam_account.email_address }
    assert_redirected_to new_session_path

    post registration_path, params: { user: { email_address: "fresh@wheelhouse.cl", password: "long-enough-1", password_confirmation: "long-enough-1" } }
    assert_redirected_to root_url
    follow_redirect!
    assert_response :ok
    delete session_path
    assert_redirected_to new_session_path

    sign_in_as @sam_account
    assert_redirected_to root_url
    get new_session_path
    assert_response :ok
  end

  test "the API answers as before" do
    get "/api/v1/services"
    assert_response :ok
    assert_equal "application/json", response.media_type

    get "/api/v1/repairs"
    assert_response :unauthorized
    assert_not_includes Api::V1::BaseController.ancestors, Pundit::Authorization
  end

  # -- Queries ---------------------------------------------------------------

  test "the repairs index runs a fixed number of queries for each role" do
    add_repairs = lambda do |prefix, count|
      count.times do |i|
        customer = Customer.create!(name: "#{prefix} #{i}", phone: "1")
        bike = Bike.create!(make: "M", model: "X", color: "Red", serial_number: "#{prefix}-#{i}", customer: customer)
        taker = account("#{prefix}#{i}@wheelhouse.cl", mechanic: Mechanic.create!(name: "#{prefix} #{i}", role: "Mechanic"))
        RepairOrder.create!(bike: bike, promised_on: Date.current + 1, mechanic: @sam, taken_in_by: taker)
      end
    end
    add_repairs.call("a", 2)

    before = [ @owner, @counter, @sam_account ].to_h do |user|
      sign_in_as user
      count = count_queries { get repair_orders_path }
      delete session_path
      [ user, count ]
    end

    add_repairs.call("b", 8)

    before.each do |user, expected|
      sign_in_as user
      assert_equal expected, count_queries { get repair_orders_path }, user.email_address
      delete session_path
    end
  end
end
