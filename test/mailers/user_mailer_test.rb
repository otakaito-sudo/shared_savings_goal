require "test_helper"

class UserMailerTest < ActionMailer::TestCase
  test "account_activation" do
    user = User.create!(name: "Test", email: "test@example.com", password: "foobar")
    mail = UserMailer.account_activation(user)

    assert_equal "アカウントを有効化してください", mail.subject
    assert_equal [ user.email ], mail.to
    assert_equal [ "from@example.com" ], mail.from

    [ mail.text_part, mail.html_part ].each do |part|
      body = part.body.decoded
      assert_match user.name, body
      assert_match user.activation_token, body
      assert_match CGI.escape(user.email), body
    end
  end

  test "password_reset" do
    user=User.create!(name: "Test", email: "test@example.com", password: "foobar")
    user.create_reset_digest
    mail=UserMailer.password_reset(user)

    assert_equal "パスワードを再設定してください", mail.subject
    assert_equal [ user.email ], mail.to
    assert_equal [ "from@example.com" ], mail.from

    [ mail.text_part, mail.html_part ].each do |part|
      body=part.body.decoded
      assert_match user.name, body
      assert_match user.reset_token, body
      assert_match CGI.escape(user.email), body
    end
  end
end
