class MockupsController < ApplicationController
  def dropoff
  end

  def repair_board
    @bikes = [
      { make: "Trek", model: "Fast 300", promised_date: "20/8", status: "Final checks", overdue: true },
      { make: "Giant", model: "Escape 2", promised_date: "22/8", status: "60%", overdue: false },
      { make: "Specialized", model: "Sirrus", promised_date: "24/8", status: "In queue", overdue: false },
      { make: "Cannondale", model: "Quick 4", promised_date: "25/8", status: "In queue", overdue: false },
      { make: "Trek", model: "Domane", promised_date: "18/8", status: "Delivered", overdue: false },
      { make: "Giant", model: "Talon", promised_date: "19/8", status: "Delivered", overdue: false }
    ]
  end

  def repair_detail
    @bike = { type: "Bike", make: "Trek", model: "Fast 300", serial: "TRK-1001" }
    @items = [
      { name: "24\" Wheel", id: "1001001", sku: "WHL-24", price: 100.00, quantity: 2, total: 200.00 }
    ]
  end

  def quote_approval
    @bike = { type: "Bike", make: "Trek", model: "Fast 300", serial: "TRK-1001" }
    @items = [
      { name: "24\" Wheel", id: "1001001", price: 100.00, quantity: 2, total: 200.00, status: :accepted },
      { name: "Brake Pads", id: "1001002", price: 25.00, quantity: 1, total: 25.00, status: :denied }
    ]
  end
end
