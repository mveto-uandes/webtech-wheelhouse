# The owner and the counter read every repair. A mechanic reads only the
# repairs assigned to them: the ones whose mechanic is the staff member their
# account belongs to. The scope and show? answer the same for every repair.
#
# A handed-back repair (completed, the last state of the lifecycle) is the
# owner's alone to edit.
class RepairPolicy < ApplicationPolicy
  # Every field of the repair's form.
  ALL_ATTRIBUTES = [
    :bike_id, :mechanic_id, :status, :reported_problem, :diagnosis, :promised_on, :handed_back_at,
    intake_photos: [],
    repair_line_items_attributes: [ [ :id, :service_id, :charged_price, :_destroy ] ]
  ].freeze
  # A mechanic moves the repair along, writes what they found and adds photos.
  MECHANIC_ATTRIBUTES = [ :status, :diagnosis, intake_photos: [] ].freeze

  def index? = signed_in?
  def show? = owner? || counter? || assigned?
  def create? = owner? || counter?
  def destroy? = owner?

  def update?
    return true if owner?

    (counter? || assigned?) && !handed_back?
  end

  # A mechanic adds photos but doesn't take them away.
  def remove_intake_photo? = (owner? || counter?) && update?

  # What the form writes for this person; anything else sent is dropped.
  def permitted_attributes
    if owner? || counter?
      ALL_ATTRIBUTES
    elsif mechanic?
      MECHANIC_ATTRIBUTES
    else
      []
    end
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if owner? || counter?
        scope.all
      elsif mechanic? && user.employee_id
        scope.where(mechanic_id: user.employee_id)
      else
        scope.none
      end
    end
  end

  private

  # A mechanic's account with no staff member has no repairs of its own.
  def assigned?
    mechanic? && user.employee_id.present? && record.mechanic_id == user.employee_id
  end

  def handed_back? = record.completed?
end
