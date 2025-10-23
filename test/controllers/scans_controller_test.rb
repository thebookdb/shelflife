require "test_helper"

class ScansControllerTest < ActionDispatch::IntegrationTest
  def sign_in(user)
    post signin_path, params: { email_address: user.email_address, password: "password" }
    follow_redirect!
  end

  test "should get index" do
    sign_in users(:one)
    get scans_path
    assert_response :success
  end

  test "should create scan" do
    sign_in users(:one)
    post scans_path, params: { gtin: "1234567890123" }
    assert_response :success
  end
end
