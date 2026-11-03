ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
  end
end

class ActionDispatch::IntegrationTest
  TEST_PASSWORD = "correct-password".freeze

  private

  def sign_in_as(user, password: TEST_PASSWORD)
    post session_path, params: { email_address: user.email_address, password: password }
    assert cookies[:session_id].present?, "#{user.email_address} did not sign in"
  end
end
