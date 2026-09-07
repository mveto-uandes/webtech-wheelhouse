# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# ---------------------------------------------------------------------------
# Services (the wall price list)
# ---------------------------------------------------------------------------

SERVICES = [
  { name: "Flat tire repair", price: 12.00 },
  { name: "Tune-up (basic)", price: 45.00 },
  { name: "Tune-up (full)", price: 85.00 },
  { name: "Brake adjustment", price: 20.00 },
  { name: "Brake pad replacement", price: 30.00 },
  { name: "Gear/derailleur adjustment", price: 25.00 },
  { name: "Wheel truing", price: 22.00 },
  { name: "Chain replacement", price: 28.00 },
  { name: "Wheel replacement", price: 65.00 },
  { name: "Bearing overhaul (hubs/bottom bracket)", price: 55.00 },
  { name: "New bike assembly", price: 40.00 },
  { name: "Safety inspection", price: 15.00 },
  { name: "Cable replacement (brake or shifter)", price: 18.00 },
  { name: "Handlebar tape replacement", price: 16.00 },
  { name: "Headset adjustment", price: 24.00 },
  { name: "Headset overhaul", price: 48.00 },
  { name: "Bottom bracket replacement", price: 60.00 },
  { name: "Fork seal service", price: 70.00 },
  { name: "Rear derailleur hanger straightening", price: 14.00 },
  { name: "Spoke replacement (single)", price: 10.00 },
  { name: "Tubeless conversion", price: 38.00 },
  { name: "Pedal installation", price: 8.00 },
  { name: "Kickstand installation", price: 10.00 },
  { name: "Fender installation", price: 20.00 },
  { name: "Rack installation", price: 25.00 },
  { name: "Full bike detailing", price: 35.00 }
].freeze

services_by_name = {}
SERVICES.each do |attrs|
  services_by_name[attrs[:name]] = Service.find_or_create_by!(name: attrs[:name]) do |s|
    s.price = attrs[:price]
  end
end

# ---------------------------------------------------------------------------
# Employees
# ---------------------------------------------------------------------------

EMPLOYEES = [
  { name: "Marco Ibáñez", role: "mechanic" },
  { name: "Valentina Rojas", role: "mechanic" },
  { name: "Diego Fuentes", role: "mechanic" },
  { name: "Camila Soto", role: "counter" }
].freeze

employees_by_name = {}
EMPLOYEES.each do |attrs|
  employees_by_name[attrs[:name]] = Employee.find_or_create_by!(name: attrs[:name]) do |e|
    e.role = attrs[:role]
  end
end

mechanics = employees_by_name.values_at("Marco Ibáñez", "Valentina Rojas", "Diego Fuentes")

# ---------------------------------------------------------------------------
# Customers
# ---------------------------------------------------------------------------

CUSTOMERS = [
  { name: "Josefina Muñoz", phone: "+56 9 6123 4501" },
  { name: "Tomás Herrera", phone: "+56 9 6123 4502" },
  { name: "Antonia Vergara", phone: "+56 9 6123 4503" },
  { name: "Benjamín Castro", phone: "+56 9 6123 4504" },
  { name: "Florencia Reyes", phone: "+56 9 6123 4505" },
  { name: "Matías Pizarro", phone: "+56 9 6123 4506" },
  { name: "Isidora Contreras", phone: "+56 9 6123 4507" },
  { name: "Vicente Morales", phone: "+56 9 6123 4508" },
  { name: "Emilia Sepúlveda", phone: "+56 9 6123 4509" },
  { name: "Agustín Bravo", phone: "+56 9 6123 4510" },
  { name: "Constanza Araya", phone: "+56 9 6123 4511" }
].freeze

customers_by_name = {}
CUSTOMERS.each do |attrs|
  customers_by_name[attrs[:name]] = Customer.find_or_create_by!(name: attrs[:name]) do |c|
    c.phone = attrs[:phone]
  end
end

# ---------------------------------------------------------------------------
# Bikes
# ---------------------------------------------------------------------------
# Josefina owns two bikes. Two bikes (Giant Escape 2, black) share make/model/color
# but differ in serial number. Constanza Araya has no bikes and no repairs.

BIKES = [
  { customer: "Josefina Muñoz",     make: "Trek",        model: "FX 2",       color: "Matte black",  serial_number: "TRK-FX2-1001" },
  { customer: "Josefina Muñoz",     make: "Giant",        model: "Escape 2",   color: "Black",        serial_number: "GNT-ESC2-2001" },
  { customer: "Tomás Herrera",      make: "Giant",        model: "Escape 2",   color: "Black",        serial_number: "GNT-ESC2-2002" },
  { customer: "Antonia Vergara",    make: "Specialized",  model: "Sirrus X",   color: "Cast blue",    serial_number: "SPZ-SIRX-3001" },
  { customer: "Benjamín Castro",    make: "Cannondale",   model: "Quick 4",    color: "Graphite",     serial_number: "CAN-Q4-4001" },
  { customer: "Florencia Reyes",    make: "Trek",         model: "Domane AL2", color: "Cherry red",   serial_number: "TRK-DOM-5001" },
  { customer: "Matías Pizarro",     make: "Scott",        model: "Sub Cross",  color: "Silver",       serial_number: "SCT-SBX-6001" },
  { customer: "Isidora Contreras",  make: "Giant",        model: "Talon 3",    color: "Olive",        serial_number: "GNT-TAL-7001" },
  { customer: "Vicente Morales",    make: "Oxford",       model: "BA2570",    color: "White",        serial_number: "OXF-BA25-8001" },
  { customer: "Emilia Sepúlveda",   make: "Merida",       model: "Crossway",   color: "Teal",         serial_number: "MER-CRW-9001" },
  { customer: "Agustín Bravo",      make: "Trek",         model: "Marlin 5",   color: "Blue",         serial_number: "TRK-MAR-1101" },
  { customer: "Agustín Bravo",      make: "Trek",         model: "Marlin 5",   color: "Blue",         serial_number: "TRK-MAR-1102" }
].freeze

bikes_by_serial = {}
BIKES.each do |attrs|
  bikes_by_serial[attrs[:serial_number]] = Bike.find_or_create_by!(serial_number: attrs[:serial_number]) do |b|
    b.customer_id = customers_by_name.fetch(attrs[:customer]).id
    b.make = attrs[:make]
    b.model = attrs[:model]
    b.color = attrs[:color]
  end
end

# ---------------------------------------------------------------------------
# Repairs + line items
# ---------------------------------------------------------------------------
# Each entry describes one repair. `days_ago` anchors reported_problem/created_at
# relative to today, so overdue/historical cases stay true on any seed run date.
#
# services: list of [service_name, charged_price_or_nil] — nil means "charge the
# current list price".

today = Date.current

REPAIRS = [
  # received — just dropped off, nothing quoted yet
  {
    bike: "TRK-FX2-1001", mechanic: nil, status: "received",
    reported_problem: "Back wheel rubs the frame and makes a ticking noise while pedaling.",
    days_ago: 1, promised_days_from_drop: nil, services: []
  },
  {
    bike: "GNT-TAL-7001", mechanic: nil, status: "received",
    reported_problem: "Chain skips under load, especially climbing.",
    days_ago: 0, promised_days_from_drop: nil, services: []
  },

  # diagnosing — a mechanic has picked it up but no quote yet
  {
    bike: "SPZ-SIRX-3001", mechanic: "Marco Ibáñez", status: "diagnosing",
    reported_problem: "Front brake feels spongy and doesn't stop the bike quickly.",
    days_ago: 2, promised_days_from_drop: nil, services: []
  },
  {
    bike: "MER-CRW-9001", mechanic: "Valentina Rojas", status: "diagnosing",
    reported_problem: "Clicking sound from the bottom bracket area on every pedal stroke.",
    days_ago: 1, promised_days_from_drop: nil, services: []
  },

  # quoted — diagnosis done, price given, waiting on the customer
  {
    bike: "CAN-Q4-4001", mechanic: "Diego Fuentes", status: "quoted",
    reported_problem: "Rear derailleur won't shift into the two lowest gears.",
    diagnosis: "Derailleur hanger bent; needs straightening and a cable adjustment.",
    days_ago: 3, promised_days_from_drop: 4,
    services: [ [ "Rear derailleur hanger straightening", nil ], [ "Gear/derailleur adjustment", nil ] ]
  },

  # approved — customer said yes, work is queued
  {
    bike: "TRK-DOM-5001", mechanic: "Marco Ibáñez", status: "approved",
    reported_problem: "Both tires are worn smooth and the owner wants tubes checked too.",
    diagnosis: "Tires worn past the wear indicators; tubes are fine.",
    days_ago: 4, promised_days_from_drop: 3,
    services: [ [ "Flat tire repair", nil ], [ "Safety inspection", nil ] ]
  },

  # declined — customer heard the price and said no
  {
    bike: "SCT-SBX-6001", mechanic: "Valentina Rojas", status: "declined",
    reported_problem: "Full drivetrain is worn out and grinding in every gear.",
    diagnosis: "Chain, cassette and chainrings all need replacing; recommended a full drivetrain overhaul.",
    days_ago: 6, promised_days_from_drop: nil,
    services: []
  },

  # in_repair — approved and being worked on right now
  {
    bike: "OXF-BA25-8001", mechanic: "Diego Fuentes", status: "in_repair",
    reported_problem: "Both brakes squeal and barely slow the bike down on hills.",
    diagnosis: "Brake pads glazed and cables stretched.",
    days_ago: 2, promised_days_from_drop: 2,
    services: [ [ "Brake pad replacement", nil ], [ "Cable replacement (brake or shifter)", nil ] ]
  },

  # ready_for_pickup — done, waiting for the customer to come get it
  {
    bike: "TRK-MAR-1101", mechanic: "Marco Ibáñez", status: "ready_for_pickup",
    reported_problem: "Annual tune-up before the riding season starts.",
    diagnosis: "Standard wear on cables and chain; recommended a full tune-up.",
    days_ago: 5, promised_days_from_drop: 3,
    services: [ [ "Tune-up (full)", nil ] ]
  },

  # overdue, unhandled — promised day has already passed, still not handed back
  {
    bike: "GNT-ESC2-2001", mechanic: "Valentina Rojas", status: "in_repair",
    reported_problem: "Wheel is badly out of true and rubs the brake pad on every rotation.",
    diagnosis: "Several spokes loose; wheel needs truing and one spoke replaced.",
    days_ago: 10, promised_days_from_drop: 3,
    services: [ [ "Wheel truing", nil ], [ "Spoke replacement (single)", nil ] ]
  },

  # same-day dropoff and completion
  {
    bike: "GNT-ESC2-2002", mechanic: "Marco Ibáñez", status: "completed",
    reported_problem: "Flat rear tire, needs a quick patch before an errand this afternoon.",
    diagnosis: "Small puncture from a thorn; patched the tube.",
    days_ago: 0, promised_days_from_drop: 0, handed_back_same_day: true,
    services: [ [ "Flat tire repair", nil ] ]
  },

  # completed, discounted line item
  {
    bike: "TRK-MAR-1102", mechanic: "Diego Fuentes", status: "completed",
    reported_problem: "New bike setup: pedals, kickstand and a rear rack for commuting.",
    diagnosis: "No issues found; straightforward accessory install.",
    days_ago: 12, promised_days_from_drop: 2, handed_back_days_after_promise: 0,
    services: [ [ "Pedal installation", 5.00 ], [ "Kickstand installation", nil ], [ "Rack installation", nil ] ]
  },

  # completed, second repair on the same bike as the one above (different dates)
  {
    bike: "TRK-MAR-1102", mechanic: "Valentina Rojas", status: "completed",
    reported_problem: "Handlebar tape is torn and the grip feels loose.",
    diagnosis: "Tape worn through from commuting; replacing tape and checking headset.",
    days_ago: 30, promised_days_from_drop: 2, handed_back_days_after_promise: 0,
    services: [ [ "Handlebar tape replacement", nil ], [ "Headset adjustment", nil ] ]
  },

  # completed, ordinary case
  {
    bike: "MER-CRW-9001", mechanic: "Diego Fuentes", status: "completed",
    reported_problem: "Basic tune-up requested before a weekend trip.",
    diagnosis: "Minor cable stretch and a dry chain; standard tune-up covers it.",
    days_ago: 20, promised_days_from_drop: 2, handed_back_days_after_promise: 0,
    services: [ [ "Tune-up (basic)", nil ] ]
  },

  # completed, historical repair from before last January — charged prices differ
  # from today's list prices, showing the invoice-from-last-year rule holds.
  {
    bike: "GNT-ESC2-2001", mechanic: "Marco Ibáñez", status: "completed",
    reported_problem: "Full tune-up and new brake pads before winter storage.",
    diagnosis: "Cables, chain and brake pads all due for replacement.",
    exact_date: Date.new(today.year - 1, 11, 15), promised_days_from_drop: 4, handed_back_days_after_promise: 0,
    services: [ [ "Tune-up (full)", 75.00 ], [ "Brake pad replacement", 25.00 ] ]
  },

  # completed, another historical repair, same idea, different bike/date
  {
    bike: "SPZ-SIRX-3001", mechanic: "Valentina Rojas", status: "completed",
    reported_problem: "Wheel replacement after a pothole bent the rim beyond truing.",
    diagnosis: "Rim cracked near a spoke hole; wheel is not repairable, needs replacing.",
    exact_date: Date.new(today.year - 1, 6, 3), promised_days_from_drop: 5, handed_back_days_after_promise: 0,
    services: [ [ "Wheel replacement", 58.00 ] ]
  },

  # declined, second example, to round out coverage with a different bike/mechanic
  {
    bike: "TRK-FX2-1001", mechanic: "Diego Fuentes", status: "declined",
    reported_problem: "Suspicious creak from the fork every time the front brake is used.",
    diagnosis: "Fork seals worn and leaking; recommended a fork seal service.",
    days_ago: 15, promised_days_from_drop: nil,
    services: []
  }
].freeze

REPAIRS.each do |attrs|
  bike = bikes_by_serial.fetch(attrs[:bike])
  mechanic = attrs[:mechanic] && employees_by_name.fetch(attrs[:mechanic])

  created_on =
    if attrs[:exact_date]
      attrs[:exact_date]
    else
      today - attrs[:days_ago].days
    end

  promised_on =
    if attrs[:promised_days_from_drop]
      created_on + attrs[:promised_days_from_drop].days
    end

  handed_back_at =
    if attrs[:status] == "completed"
      if attrs[:handed_back_same_day]
        created_on.to_time + 3.hours
      elsif attrs[:handed_back_days_after_promise] && promised_on
        promised_on.to_time + attrs[:handed_back_days_after_promise].days + 2.hours
      else
        (promised_on || created_on).to_time + 2.hours
      end
    end

  repair = Repair.find_or_create_by!(
    bike_id: bike.id,
    reported_problem: attrs[:reported_problem]
  ) do |r|
    r.mechanic_id = mechanic&.id
    r.status = attrs[:status]
    r.diagnosis = attrs[:diagnosis]
    r.promised_on = promised_on
    r.handed_back_at = handed_back_at
    r.created_at = created_on.to_time + 9.hours
    r.updated_at = created_on.to_time + 9.hours
  end

  attrs[:services].each do |service_name, override_price|
    service = services_by_name.fetch(service_name)
    RepairLineItem.find_or_create_by!(repair_id: repair.id, service_id: service.id) do |li|
      li.charged_price = override_price || service.price
    end
  end
end

puts "Seeded #{Service.count} services, #{Employee.count} employees, " \
     "#{Customer.count} customers, #{Bike.count} bikes, #{Repair.count} repairs, " \
     "#{RepairLineItem.count} repair line items."
