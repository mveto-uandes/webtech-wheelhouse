# frozen_string_literal: true

# Every policy starts here, and here everything is refused: an action whose
# method nobody wrote is closed, never open. `user` is the account of the
# session, handed in by the controller (nil for a visitor); no policy reads the
# session, the params or Current itself.
class ApplicationPolicy
  # Who the account is, asked through the enum's own methods. A visitor is none.
  module Roles
    private

    def signed_in? = user.present?
    def owner? = user&.owner? || false
    def counter? = user&.counter? || false
    def mechanic? = user&.mechanic? || false
  end
  include Roles

  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def index?
    false
  end

  def show?
    false
  end

  def create?
    false
  end

  def new?
    create?
  end

  def update?
    false
  end

  def edit?
    update?
  end

  def destroy?
    false
  end

  # Shows nothing unless a policy says what its reader may see.
  class Scope
    include Roles

    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      scope.none
    end

    private

    attr_reader :user, :scope
  end
end
