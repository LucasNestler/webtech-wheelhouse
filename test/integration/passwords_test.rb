require "test_helper"

class PasswordsTest < ActionDispatch::IntegrationTest
  include ActionMailer::TestHelper

  NEW_PASSWORD = "a-brand-new-password".freeze

  def request_link(user)
    perform_enqueued_jobs { post passwords_path, params: { email_address: user.email_address } }
    ActionMailer::Base.deliveries.last
  end

  def link_path(email)
    URI(email.text_part.body.to_s[%r{http://\S+}]).path
  end

  def update_path(link)
    link.delete_suffix("/edit")
  end

  test "the whole flow: request, email, link, new password, sign in" do
    email = request_link(users(:one))
    assert_redirected_to new_session_path

    get link_path(email)
    assert_response :ok
    assert_select "label", 2
    assert_select "input.form-control", 2

    patch update_path(link_path(email)), params: { password: NEW_PASSWORD, password_confirmation: NEW_PASSWORD }
    assert_redirected_to new_session_path

    sign_in_as users(:one), password: NEW_PASSWORD
  end

  test "the request answers the same whether the address has an account or not" do
    post passwords_path, params: { email_address: users(:one).email_address }
    known = [ response.status, response.location, flash[:notice] ]

    post passwords_path, params: { email_address: "nobody@example.com" }

    assert_equal known, [ response.status, response.location, flash[:notice] ]
  end

  test "an unknown address sends nothing, and an odd parameter is not an error" do
    assert_no_enqueued_emails do
      post passwords_path, params: { email_address: "nobody@example.com" }
      post passwords_path, params: { email_address: { a: "b" } }
      post passwords_path
    end
    assert_redirected_to new_session_path
  end

  test "the email leaves from a job" do
    assert_no_difference -> { ActionMailer::Base.deliveries.size } do
      assert_enqueued_emails 1 do
        post passwords_path, params: { email_address: users(:one).email_address }
      end
    end
  end

  test "the email says Wheelhouse, has both parts, and a full URL" do
    email = request_link(users(:one))

    assert_match(/Wheelhouse/, email.subject)
    assert_match(/Wheelhouse/, email.from_address.display_name)
    assert_match(/Wheelhouse/, email.html_part.body.to_s)
    assert_match(/Wheelhouse/, email.text_part.body.to_s)
    assert_match %r{http://example\.com/passwords/\S+/edit}, email.text_part.body.to_s
    assert_match %r{http://example\.com/passwords/\S+/edit}, email.html_part.body.to_s
  end

  test "the link stops working after the password is changed" do
    path = link_path(request_link(users(:one)))
    patch update_path(path), params: { password: NEW_PASSWORD, password_confirmation: NEW_PASSWORD }

    get path
    assert_redirected_to new_password_path
    assert flash[:alert].present?
  end

  test "the link stops working after the time the generator sets" do
    path = link_path(request_link(users(:one)))

    travel 16.minutes do
      get path
      assert_redirected_to new_password_path
    end
  end

  test "a refused password stays on the form with the real message, and the link keeps working" do
    path = link_path(request_link(users(:one)))
    digest = users(:one).password_digest

    patch update_path(path), params: { password: "short", password_confirmation: "short" }
    assert_response :unprocessable_entity
    assert_select ".invalid-feedback", /#{User::PASSWORD_MINIMUM_LENGTH} characters/

    patch update_path(path), params: { password: NEW_PASSWORD, password_confirmation: "does-not-match-it" }
    assert_response :unprocessable_entity
    assert_select ".invalid-feedback", /match/

    patch update_path(path), params: { password: NEW_PASSWORD }
    assert_response :unprocessable_entity

    patch update_path(path), params: { password: "", password_confirmation: "" }
    assert_response :unprocessable_entity
    assert_select ".invalid-feedback", /blank/

    assert_equal digest, users(:one).reload.password_digest
    get path
    assert_response :ok
  end
end
