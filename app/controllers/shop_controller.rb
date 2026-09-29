class ShopController < ApplicationController
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
