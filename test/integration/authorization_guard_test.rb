require "test_helper"

# A controller that forgets its policy fails, without a line written in it.
class ForgetfulController < ApplicationController
  def index = render(plain: "everything")
  def show = (authorize(Service); render(plain: "asked, but no scope needed"))
  def edit = render(plain: "nobody asked")
end

class AuthorizationGuardTest < ActionDispatch::IntegrationTest
  test "an action that doesn't ask a policy, or an index without a scope, raises" do
    with_routing do |set|
      set.draw do
        get "forgetful" => "forgetful#index"
        get "forgetful/edit" => "forgetful#edit"
        get "forgetful/show" => "forgetful#show"
        resource :session, only: :new
      end
      # with_routing starts a fresh integration session, so sign in inside it.
      sign_in_as users(:one)
      assert_raises(Pundit::AuthorizationNotPerformedError) { get "/forgetful/edit" }
      assert_raises(Pundit::AuthorizationNotPerformedError) { get "/forgetful" }
      get "/forgetful/show"
      assert_response :success
    end
  end

  test "a refused request answers 403 in the layout, a visitor is sent to sign in" do
    get catalog_customers_path
    assert_redirected_to new_session_path

    sign_in_as users(:one) # default role: mechanic
    get catalog_customers_path
    assert_response :forbidden
    assert_select "nav"
    assert_select "h1", /not allowed/
  end
end
