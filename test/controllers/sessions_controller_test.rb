require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  setup { @user = User.take }

  test "new" do
    get new_session_path
    assert_response :success
  end

  test "create with valid credentials" do
    post session_path, params: { email_address: @user.email_address, password: "password" }

    assert_redirected_to root_path
    assert cookies[:session_id]
  end

  test "create with invalid credentials" do
    post session_path, params: { email_address: @user.email_address, password: "wrong" }

    assert_response :unprocessable_content
    assert_nil cookies[:session_id]
  end

  test "a wrong address and a wrong password get the same message" do
    post session_path, params: { email_address: @user.email_address, password: "wrong" }
    wrong_password = css_select(".alert").text.squish
    post session_path, params: { email_address: "nobody@example.com", password: "password" }

    assert_equal wrong_password, css_select(".alert").text.squish
  end

  test "the session cookie is HttpOnly and SameSite=Lax" do
    post session_path, params: { email_address: @user.email_address, password: "password" }

    cookie = Array(response.headers["Set-Cookie"]).join("\n").lines.find { |line| line.start_with?("session_id=") }
    assert_match(/httponly/i, cookie)
    assert_match(/samesite=lax/i, cookie)
  end

  test "destroy" do
    sign_in_as(User.take)

    delete session_path

    assert_redirected_to new_session_path
    assert_empty cookies[:session_id]
  end
end
