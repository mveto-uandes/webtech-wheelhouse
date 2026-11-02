require "test_helper"

class PasswordsControllerTest < ActionDispatch::IntegrationTest
  setup { @user = User.take }

  test "new" do
    get new_password_path
    assert_response :success
  end

  test "create" do
    post passwords_path, params: { email_address: @user.email_address }
    assert_enqueued_email_with PasswordsMailer, :reset, args: [ @user ]
    assert_redirected_to new_session_path

    follow_redirect!
    assert_notice "If that address has an account"
  end

  test "create for an unknown user redirects but sends no mail" do
    post passwords_path, params: { email_address: "missing-user@example.com" }
    assert_enqueued_emails 0
    assert_redirected_to new_session_path

    follow_redirect!
    assert_notice "If that address has an account"
  end

  test "edit" do
    get edit_password_path(@user.password_reset_token)
    assert_response :success
  end

  test "edit with invalid password reset token" do
    get edit_password_path("invalid token")
    assert_redirected_to new_password_path

    follow_redirect!
    assert_notice "no longer valid"
  end

  test "update" do
    assert_changes -> { @user.reload.password_digest } do
      put password_path(@user.password_reset_token), params: { password: "a-new-password", password_confirmation: "a-new-password" }
      assert_redirected_to new_session_path
    end

    follow_redirect!
    assert_notice "Your password was changed"
  end

  test "update with non matching passwords" do
    token = @user.password_reset_token
    assert_no_changes -> { @user.reload.password_digest } do
      put password_path(token), params: { password: "long-enough-1", password_confirmation: "long-enough-2" }
      assert_response :unprocessable_content
    end

    assert_notice "doesn't match the password"
  end

  test "update with a short or blank password" do
    token = @user.password_reset_token
    assert_no_changes -> { @user.reload.password_digest } do
      put password_path(token), params: { password: "short", password_confirmation: "short" }
      assert_response :unprocessable_content
      assert_notice "at least 10 characters"

      put password_path(token), params: { password: "", password_confirmation: "" }
      assert_response :unprocessable_content
    end
  end

  test "the link stops working once the password changes" do
    token = @user.password_reset_token
    put password_path(token), params: { password: "a-new-password", password_confirmation: "a-new-password" }

    get edit_password_path(token)
    assert_redirected_to new_password_path
  end

  private
    def assert_notice(text)
      assert_select "div", /#{text}/
    end
end
