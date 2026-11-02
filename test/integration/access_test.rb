require "test_helper"

class AccessTest < ActionDispatch::IntegrationTest
  test "a visitor is sent to sign in and lands on the page they asked for" do
    get catalog_repairs_path
    assert_redirected_to new_session_path

    post session_path, params: { email_address: users(:one).email_address, password: "password" }
    assert_redirected_to catalog_repairs_url
  end

  test "the price list and the services are open; changing a service is not" do
    get services_path
    assert_response :success
    get catalog_services_path
    assert_response :success
    get new_catalog_service_path
    assert_redirected_to new_session_path
  end

  test "the home page is closed" do
    get root_path
    assert_redirected_to new_session_path
  end

  test "the visitor's navbar links only to open pages" do
    get services_path
    assert_select "nav a[href='#{new_session_path}']"
    assert_select "nav a[href^='/catalog']", count: 0
    assert_select "nav a[href='#{root_path}']", count: 0
  end

  test "the navbar names who is signed in and their role" do
    sign_in_as users(:one)
    get services_path
    assert_select "nav", /#{users(:one).email_address}/
    assert_select "nav form[action='#{session_path}'] input[name='_method'][value='delete']"
  end

  test "signing out by GET does nothing" do
    sign_in_as users(:one)
    get "/session"
    assert_response :not_found
    get catalog_repairs_path
    assert_response :success
  end

  test "the API answers without a session and never redirects" do
    get api_v1_services_path
    assert_response :success
    get api_v1_repairs_path
    assert_response :unauthorized
  end
end
