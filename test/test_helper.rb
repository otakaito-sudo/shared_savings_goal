ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    setup { Rails.cache.clear }
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...

    def create_user(name: "太郎", email: nil)
      User.create!(name: name, email: email || "#{SecureRandom.hex(4)}@example.com",
                 password: "password")
    end

    def create_goal(creator:, target_amount: 100_000)
      SavingGoal.create!(name: "沖縄旅行", purpose: "旅費", target_amount: target_amount,
                       deadline: Date.current + 30, creator: creator)
    end

    def join(goal:, user:, role: :member)
      Membership.create!(saving_goal: goal, user: user, role: role)
    end
  end

  class ActionDispatch::IntegrationTest
    # 　テストの中でログインする
    def log_in_as(user, password: "foobar", remember_me: "0")
      post login_path, params: { email: user.email, password: password, remember_me: remember_me }
    end

    def create_activated_user(name, email)
      user=User.create!(name: name, email: email, password: "foobar")
      user.update_columns(activated: true, activated_at: Time.zone.now)
      user
    end
  end
end
