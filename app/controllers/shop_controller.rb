class ShopController < ApplicationController
  def home
  end

  def services
    @jobs = [
      { name: "Service 1", price: 8888 },
      { name: "Service 2", price: 8888 },
      { name: "Service 3", price: 8888 },
      { name: "Service 4", price: 8888 },
      { name: "Service 5", price: 8888 },
      { name: "Service 6", price: 8888 },
      { name: "Service 7", price: 8888 },
      { name: "Service 8", price: 8888 },
      { name: "Service 9", price: 8888 },
      { name: "Service 10", price: 8888 },
      { name: "Service 11", price: 8888 },
      { name: "Service 12", price: 8888 }
    ]
  end

  def visiting
  end

  def about
  end
end
