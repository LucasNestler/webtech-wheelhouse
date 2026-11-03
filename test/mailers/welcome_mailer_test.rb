require "test_helper"

class WelcomeMailerTest < ActionMailer::TestCase
  test "names the address, links to sign in, and has both parts" do
    email = WelcomeMailer.welcome(users(:one))

    assert_equal [ "one@example.com" ], email.to
    assert_match(/Wheelhouse/, email.subject)
    [ email.html_part, email.text_part ].each do |part|
      assert_match "one@example.com", part.body.to_s
      assert_match "http://example.com/session/new", part.body.to_s
    end
  end

  test "has a preview" do
    assert_includes WelcomeMailerPreview.emails, "welcome"
    assert_match(/Wheelhouse/, WelcomeMailerPreview.new.welcome.subject)
  end
end
