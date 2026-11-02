# The static staff-workflow mockups from Lab 4: fake data, for any account.
class MockupPolicy < ApplicationPolicy
  def dropoff? = signed_in?
  def repair_board? = signed_in?
  def repair_detail? = signed_in?
  def quote_approval? = signed_in?
end
