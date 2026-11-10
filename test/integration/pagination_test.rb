require "test_helper"

class PaginationTest < ActionDispatch::IntegrationTest
  setup do
    @manager = create_activated_user("管理者", "manager-#{SecureRandom.hex(4)}@example.com")
    @goal = create_goal(creator: @manager)
    join(goal: @goal, user: @manager, role: :manager)

    25.times do |i|
      @goal.activities.create!(actor: @manager, kind: :member_joined, created_at: (25 - i).minutes.ago)
    end
  end

  test "活動履歴を20件ずつ表示し、ページが重ならない" do
    log_in_as(@manager)

    get saving_goal_activities_path(@goal)
    assert_select "ul.activities li", 20
    assert_select "a[href*='page=2']"
    first_page = css_select("ul.activities li").map(&:text)

    get saving_goal_activities_path(@goal, page: 2)
    assert_select "ul.activities li", 5
    second_page = css_select("ul.activities li").map(&:text)

    assert_empty first_page & second_page
  end

  test "目標画面の活動履歴は最新5件だけ" do
    log_in_as(@manager)

    get saving_goal_path(@goal)
    assert_select "ul.activities li", 5
    assert_select "a[href=?]", saving_goal_activities_path(@goal)
  end

  test "参加していない目標の履歴は見られない" do
    other = create_activated_user("他人", "other-#{SecureRandom.hex(4)}@example.com")
    log_in_as(other)

    get saving_goal_activities_path(@goal)
    assert_response :not_found
  end
end