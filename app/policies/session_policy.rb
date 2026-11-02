# Signing out ends the caller's own session, which any account may do.
class SessionPolicy < ApplicationPolicy
  def destroy? = signed_in?
end
