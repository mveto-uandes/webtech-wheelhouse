# Customers are the counter's: it adds, edits and reads them. Only the owner
# deletes one. Mechanics work on bikes, not with the customers' phone numbers.
class CustomerPolicy < ApplicationPolicy
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
