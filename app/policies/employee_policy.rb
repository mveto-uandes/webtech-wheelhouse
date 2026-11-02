# Everyone who works here reads the staff list; only the owner changes it.
class EmployeePolicy < ApplicationPolicy
  def index? = signed_in?
  def show? = signed_in?
  def create? = owner?
  def update? = owner?
  def destroy? = owner?

  class Scope < ApplicationPolicy::Scope
    def resolve = signed_in? ? scope.all : scope.none
  end
end
