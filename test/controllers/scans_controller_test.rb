require "test_helper"

class ScansControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get scans_path
    assert_response :success
  end

  test "should create scan" do
    post scans_path
    assert_response :success
  end
end
