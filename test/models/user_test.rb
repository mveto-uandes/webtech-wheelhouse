require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "downcases and strips email_address" do
    user = User.new(email_address: " DOWNCASED@EXAMPLE.COM ")
    assert_equal("downcased@example.com", user.email_address)
  end

  test "the default role is mechanic" do
    assert User.new.mechanic?
  end

  test "a password shorter than the minimum is refused, saying the minimum" do
    user = User.new(email_address: "a@example.com", password: "x" * 9)
    assert_not user.valid?
    assert_includes user.errors.full_messages, "Password must be at least 10 characters long"
  end

  test "the database refuses an address that differs only in case" do
    assert_raises(ActiveRecord::RecordNotUnique) do
      User.new(email_address: users(:one).email_address.upcase, password: "long-enough").save!(validate: false)
    end
  end
end
