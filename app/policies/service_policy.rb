# The price list is public; only the owner changes it.
class ServicePolicy < ApplicationPolicy
  def index? = true
  def show? = true
  def create? = owner?
  def update? = owner?
  def destroy? = owner?

  class Scope < ApplicationPolicy::Scope
    def resolve = scope.all
  end
end
