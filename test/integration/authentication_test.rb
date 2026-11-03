require "test_helper"

class AuthenticationTest < ActionDispatch::IntegrationTest
  setup do
    @service = Service.create!(name: "Brakes", default_price: 35)
    customer = Customer.create!(name: "Test", phone: "555")
    @bike = Bike.create!(make: "Giant", model: "Escape", color: "Blue", serial_number: "SN-A-1", customer: customer)
    @repair = RepairOrder.create!(bike: @bike, promised_on: Date.current + 2)
    @mechanic = Mechanic.create!(name: "Sam Vasquez", role: "Lead Mechanic")
  end

  def closed_pages
    [ root_path, visit_path, about_path,
      customers_path, new_customer_path, customer_path(@bike.customer), edit_customer_path(@bike.customer),
      bikes_path, new_bike_path, bike_path(@bike), edit_bike_path(@bike),
      repair_orders_path, new_repair_order_path, repair_order_path(@repair), edit_repair_order_path(@repair),
      mechanics_path, new_mechanic_path, mechanic_path(@mechanic), edit_mechanic_path(@mechanic),
      new_service_path, edit_service_path(@service) ]
  end

  test "every closed page sends a visitor to sign in" do
    closed_pages.each do |path|
      get path
      assert_redirected_to new_session_path, path
    end
  end

  test "writes are closed to a visitor" do
    assert_no_difference -> { Service.count } do
      post services_path, params: { service: { name: "Wash", default_price: 5, active: true } }
    end
    assert_redirected_to new_session_path

    patch service_path(@service), params: { service: { name: "Changed" } }
    assert_redirected_to new_session_path
    assert_equal "Brakes", @service.reload.name

    delete service_path(@service)
    assert_redirected_to new_session_path
    assert Service.exists?(@service.id)

    post customers_path, params: { customer: { name: "X", phone: "1" } }
    assert_redirected_to new_session_path
  end

  test "the open pages answer a visitor" do
    [ new_session_path, new_registration_path, new_password_path, services_path, service_path(@service) ].each do |path|
      get path
      assert_response :ok, path
    end
  end

  test "signing in lands on the page that was asked for" do
    get repair_order_path(@repair)
    assert_redirected_to new_session_path

    post session_path, params: { email_address: users(:one).email_address, password: TEST_PASSWORD }

    assert_redirected_to repair_order_url(@repair)
    follow_redirect!
    assert_response :ok
  end

  test "signing in with no page asked for lands on the home page" do
    sign_in_as users(:one)
    assert_redirected_to root_url
  end

  test "a wrong address and a wrong password show the same message" do
    post session_path, params: { email_address: users(:one).email_address, password: "not-the-password" }
    assert_redirected_to new_session_path
    wrong_password = flash[:alert]

    post session_path, params: { email_address: "nobody@example.com", password: "not-the-password" }
    assert_redirected_to new_session_path

    assert wrong_password.present?
    assert_equal wrong_password, flash[:alert]
    assert cookies[:session_id].blank?
  end

  test "the sign-in and forgotten password forms leave the checking to the server" do
    get new_session_path
    assert_select "form[action=?][novalidate]", session_path

    get new_password_path
    assert_select "form[action=?][novalidate]", passwords_path

    post session_path, params: { email_address: "no-at-sign", password: "x" }
    assert_redirected_to new_session_path
    assert flash[:alert].present?
  end

  test "signing in does not care about the case of the address" do
    post session_path, params: { email_address: "ONE@Example.com", password: TEST_PASSWORD }
    assert cookies[:session_id].present?
  end

  test "the sign-in form has labels, Bootstrap and the layout" do
    get new_session_path

    assert_select "nav.navbar"
    assert_select "label[for=email_address]"
    assert_select "label[for=password]"
    assert_select "input.form-control[name=email_address]"
    assert_select "input.form-control[name=password]"
    assert_select "input.btn.btn-primary"
    assert_select "a[href=?]", new_registration_path
    assert_select "a[href=?]", new_password_path
  end

  test "the session cookie is HttpOnly and SameSite=Lax" do
    post session_path, params: { email_address: users(:one).email_address, password: TEST_PASSWORD }

    cookie = Array(response.headers["Set-Cookie"]).join("\n").lines.find { |line| line.start_with?("session_id=") }
    assert cookie, "no session_id cookie"
    assert_match(/httponly/i, cookie)
    assert_match(/samesite=lax/i, cookie)
  end

  test "signing out is a DELETE, lands on sign in and closes the pages" do
    sign_in_as users(:one)
    get repair_orders_path
    assert_select "form[action=?]", session_path do
      assert_select "input[name=_method][value=delete]"
    end

    assert_no_difference -> { users(:one).sessions.count } do
      get "/session"
      assert_response :not_found
    end

    assert_difference -> { users(:one).sessions.count }, -1 do
      delete session_path
    end
    assert_redirected_to new_session_path
    assert_response :see_other

    get repair_orders_path
    assert_redirected_to new_session_path
  end

  test "the navigation bar of a visitor has the price list and sign in, and nothing closed" do
    [ services_path, service_path(@service), new_session_path ].each do |path|
      get path

      assert_select "nav.navbar a[href=?]", services_path
      assert_select "nav.navbar a[href=?]", new_session_path
      assert_select "nav.navbar a[href=?]", root_path, count: 0
      assert_select "nav.navbar a[href=?]", repair_orders_path, count: 0
      assert_select "nav.navbar a[href=?]", customers_path, count: 0
      assert_select "nav.navbar form[action=?]", session_path, count: 0
    end
  end

  test "a visitor on the price list sees no way to write" do
    get services_path
    assert_select "a[href=?]", new_service_path, count: 0

    get service_path(@service)
    assert_select "a[href=?]", edit_service_path(@service), count: 0
    assert_select "form[action=?]", service_path(@service), count: 0
  end

  test "every page shows who is signed in: the name and the role" do
    users(:one).update!(mechanic: @mechanic, role: :counter)
    sign_in_as users(:one)

    [ root_path, repair_orders_path, services_path, service_path(@service), new_session_path, new_password_path ].each do |path|
      get path
      assert_select "nav.navbar", /Sam Vasquez \(Counter\)/, path
      assert_select "nav.navbar form[action=?]", session_path
    end
  end

  test "an account with no member of the staff shows its address" do
    sign_in_as users(:two)

    get root_path
    assert_select "nav.navbar", /two@example\.com \(Mechanic\)/
  end

  test "a member of the staff with an account cannot be destroyed, and the page says so" do
    users(:two).update!(mechanic: @mechanic)
    @repair.update!(mechanic: @mechanic)
    sign_in_as users(:one)

    assert_no_difference -> { Mechanic.count } do
      delete mechanic_path(@mechanic)
    end
    assert_redirected_to mechanic_path(@mechanic)
    assert flash[:alert].present?
    assert_equal @mechanic, @repair.reload.mechanic
  end

  test "a member of the staff with no account can still be destroyed" do
    sign_in_as users(:one)

    assert_difference -> { Mechanic.count }, -1 do
      delete mechanic_path(@mechanic)
    end
  end

  test "no page lists or edits accounts" do
    assert_empty Rails.application.routes.routes.map { |route| route.path.spec.to_s }.grep(%r{/(users|accounts)\b})
  end

  test "the API answers with the token and without a session, and never redirects" do
    get "/api/v1/services"
    assert_response :ok

    get "/api/v1/repairs"
    assert_response :unauthorized
    assert_equal "application/json", response.media_type

    assert_not_includes Api::V1::BaseController.ancestors, Authentication
  end
end
