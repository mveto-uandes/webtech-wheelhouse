class ApplicationController < ActionController::Base
  # Every page asks for a session unless its controller opens an action by name.
  include Authentication
  # And every action asks a policy (app/policies) whether this account may do it.
  include Pundit::Authorization

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  # An action that never asked its policy raises, and so does an index that
  # isn't built from a policy scope. This covers every controller that inherits
  # from this one, including ones not written yet. The few public actions that
  # skip the check are listed in docs/decisions.md (Lab 12).
  after_action :verify_authorized
  after_action :verify_policy_scoped, if: -> { action_name == "index" }

  rescue_from Pundit::NotAuthorizedError, with: :forbidden

  private

  # The account of the session, or nil for a visitor. Public actions skip
  # require_authentication, so the session is resumed here too.
  def pundit_user
    resume_session
    Current.user
  end

  # The 403 page, in the application's layout. Nothing was written: policies
  # are asked before any save or destroy.
  def forbidden
    render "errors/forbidden", status: :forbidden
  end
end
