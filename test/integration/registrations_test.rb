require "test_helper"

class RegistrationsTest < ActionDispatch::IntegrationTest
  include ActionMailer::TestHelper

  VALID = { email_address: "New.Person@Wheelhouse.cl", password: "long-enough-1", password_confirmation: "long-enough-1" }.freeze

  test "the form follows the rules and is linked from sign in" do
    get new_registration_path

    assert_select "label[for=user_email_address]"
    assert_select "label[for=user_password]"
    assert_select "label[for=user_password_confirmation]"
    assert_select "input.form-control", count: 3
    assert_select "[name='user[role]']", count: 0
    assert_select "[name='user[mechanic_id]']", count: 0
  end

  test "signing up creates the account and signs it in" do
    assert_difference -> { User.count }, 1 do
      post registration_path, params: { user: VALID }
    end

    user = User.last
    assert_equal "new.person@wheelhouse.cl", user.email_address
    assert user.role_mechanic?
    assert_redirected_to root_url
    assert cookies[:session_id].present?

    follow_redirect!
    assert_response :ok
    assert_select "nav.navbar", /new\.person@wheelhouse\.cl/
  end

  test "the role and the member of the staff cannot be chosen" do
    staff = Mechanic.create!(name: "Sam", role: "Lead")

    post registration_path, params: { user: VALID.merge(role: User.roles.keys.first, mechanic_id: staff.id) }

    user = User.last
    assert_equal User.column_defaults["role"], user.role
    assert_nil user.mechanic_id
  end

  test "a refused sign-up answers 422, keeps the address, empties the passwords and sends nothing" do
    assert_no_enqueued_emails do
      assert_no_difference -> { User.count } do
        post registration_path, params: { user: { email_address: "new@wheelhouse.cl", password: "short", password_confirmation: "short" } }
      end
    end

    assert_response :unprocessable_entity
    assert_select "input[name='user[email_address]'][value=?]", "new@wheelhouse.cl"
    assert_select "input[name='user[password]'][value]", count: 0
    assert_select "input[name='user[password_confirmation]'][value]", count: 0
    assert_select "input.is-invalid[name='user[password]']"
    assert_select ".invalid-feedback", /#{User::PASSWORD_MINIMUM_LENGTH} characters/
    assert cookies[:session_id].blank?
  end

  test "an address with a bad format reaches the server and shows its message next to the field" do
    get new_registration_path
    assert_select "form[action=?][novalidate]", registration_path

    post registration_path, params: { user: VALID.merge(email_address: "no-at-sign") }

    assert_response :unprocessable_entity
    assert_select "input.is-invalid[name='user[email_address]'][value=?]", "no-at-sign"
    assert_select ".invalid-feedback", /is invalid/
  end

  test "an address already taken, in any case, is refused" do
    post registration_path, params: { user: VALID.merge(email_address: "ONE@example.com") }

    assert_response :unprocessable_entity
    assert_select "input.is-invalid[name='user[email_address]']"
  end

  test "an empty form is refused" do
    post registration_path, params: { user: { email_address: "", password: "", password_confirmation: "" } }

    assert_response :unprocessable_entity
    assert_select "input.is-invalid[name='user[email_address]']"
    assert_select "input.is-invalid[name='user[password]']"
  end

  test "a request with no confirmation is refused" do
    post registration_path, params: { user: VALID.except(:password_confirmation) }
    assert_response :unprocessable_entity
  end

  test "the welcome email leaves from a job, after the response" do
    assert_no_difference -> { ActionMailer::Base.deliveries.size } do
      assert_enqueued_emails 1 do
        post registration_path, params: { user: VALID }
      end
    end
  end
end
