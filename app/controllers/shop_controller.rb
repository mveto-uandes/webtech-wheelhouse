class ShopController < ApplicationController
  def home
  end

  def services
    @services = Service.order(:name)
  end

  def visiting
  end

  def about
  end
end
