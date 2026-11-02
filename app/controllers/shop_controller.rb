class ShopController < ApplicationController
  # The wall price list is the only public page of the shop.
  allow_unauthenticated_access only: :services
  before_action { authorize :shop }

  def home
  end

  def services
    @services = Service.by_name
  end

  def visiting
  end

  def about
  end
end
