require "test_helper"

class Deposits::ConfirmConcurrencyTest < ActiveSupport::TestCase
  self.use_transactional_tests=false

  setup do
    @manager=create_user(name: "管理者")
    @member=create_user(name: "メンバー")
    @goal=create_goal(creator: @manager, target_amount: 100_000)
    join(goal: @goal, user: @manager, role: :manager)
    join(goal: @goal, user: @member)
    @a=Deposit.create!(saving_goal: @goal, member: @member, request_amount: 60_000)
    @b=Deposit.create!(saving_goal: @goal, member: @member, request_amount: 60_000)
  end

  teardown do
    Deposit.delete_all
    Membership.delete_all
    SavingGoal.delete_all
    User.delete_all
  end

  test "同時に確認しても目標金額を超えない" do
    results=[]
    mutex=Mutex.new

    threads=[ @a, @b ].map do |deposit|
      Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          begin
            Deposits::Confirm.new(deposit: deposit, reviewer: @manager).call
            mutex.synchronize { results << :confirmed }
          rescue Deposits::Base::ExceedsTarget
            mutex.synchronize { results << :exceeded }
          end
        end
      end
    end
    threads.each(&:join)

    assert_equal 1, results.count(:confirmed)
    assert_equal 1, results.count(:exceeded)
    assert_equal 60_000, @goal.reload.current_amount
    assert_equal 1, @goal.deposits.confirmed.count
  end
end
