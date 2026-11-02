# Payments are money: the owner and the counter read them. Nobody writes one
# from a page (the payments pages are read-only).
class PaymentPolicy < ApplicationPolicy
  def index? = owner? || counter?
  def show? = owner? || counter?

  class Scope < ApplicationPolicy::Scope
    def resolve = owner? || counter? ? scope.all : scope.none
  end
end
