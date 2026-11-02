# The shop's own pages, which have no model. The wall price list is public;
# the rest is for the people of the workshop.
class ShopPolicy < ApplicationPolicy
  def services? = true
  def home? = signed_in?
  def visiting? = signed_in?
  def about? = signed_in?
end
