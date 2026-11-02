# Bikes follow their customers: the counter adds, edits and reads them, only
# the owner deletes one, and mechanics reach a bike only through its repairs.
class BikePolicy < ApplicationPolicy
  def index? = front_desk?
  def show? = front_desk?
  def create? = front_desk?
  def update? = front_desk?
  def destroy? = owner?

  class Scope < ApplicationPolicy::Scope
    def resolve = owner? || counter? ? scope.all : scope.none
  end

  private

  def front_desk? = owner? || counter?
end
