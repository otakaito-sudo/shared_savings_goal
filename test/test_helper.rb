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
end
