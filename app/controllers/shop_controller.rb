class ShopController < ApplicationController
  def home
  end

  def services
    @jobs = [
      { name: "Flat tire repair", price: 12 },
      { name: "Tune-up (basic)", price: 45 },
      { name: "Tune-up (full)", price: 85 },
      { name: "Brake adjustment", price: 20 },
      { name: "Brake pad replacement", price: 30 },
      { name: "Gear/derailleur adjustment", price: 25 },
      { name: "Wheel truing", price: 22 },
      { name: "Chain replacement", price: 28 },
      { name: "Wheel replacement", price: 65 },
      { name: "Bearing overhaul (hubs/bottom bracket)", price: 55 },
      { name: "New bike assembly", price: 40 },
      { name: "Safety inspection", price: 15 }
    ]
  end

  def visiting
  end

  def about
  end
end
