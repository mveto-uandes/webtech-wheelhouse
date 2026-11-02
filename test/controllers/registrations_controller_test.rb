require "test_helper"

class RegistrationsControllerTest < ActionDispatch::IntegrationTest
  test "new" do
    get new_registration_path
    assert_response :success
  end

  test "signs up with the default role, signs in and sends the welcome email later" do
    assert_difference -> { User.count } do
      assert_enqueued_email_with WelcomeMailer, :welcome, args: ->(args) { args.first.email_address == "new@example.com" } do
        post registration_path, params: { user: {
          email_address: "New@Example.com", password: "long-enough", password_confirmation: "long-enough",
          role: "owner", employee_id: Employee.first&.id
        } }
      end
    end

    user = User.find_by!(email_address: "new@example.com")
    assert user.mechanic?
    assert_nil user.employee
    assert cookies[:session_id].present?
  end

  test "a refused sign-up answers 422, keeps the address and sends nothing" do
    assert_no_difference -> { User.count } do
      post registration_path, params: { user: { email_address: "new@example.com", password: "short", password_confirmation: "short" } }
    end

    assert_response :unprocessable_content
    assert_enqueued_emails 0
    assert_select "input[name='user[email_address]'][value='new@example.com']"
    assert_select "input[name='user[password]']:not([value])"
    assert_select ".invalid-feedback", /at least 10 characters/
  end

  test "an address that differs only in case is taken" do
    post registration_path, params: { user: {
      email_address: users(:one).email_address.upcase, password: "long-enough", password_confirmation: "long-enough"
    } }
    assert_response :unprocessable_content
  end
end
