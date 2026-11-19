require "test_helper"

class GuideTest < ActionDispatch::IntegrationTest
  test "使い方ページが開ける" do
    get guide_path
    assert_response :success
    assert_select "h1", "使い方"
  end
end
