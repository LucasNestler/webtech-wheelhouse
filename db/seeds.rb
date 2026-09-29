RepairLineItem.delete_all
RepairOrder.delete_all
Bike.delete_all
Customer.delete_all
Mechanic.delete_all
Service.delete_all

puts "Clearing old data..."

puts "Seeding Staff..."
mechanic_sam = Mechanic.create!(name: "Sam Vasquez", role: "Lead Mechanic")
mechanic_alex = Mechanic.create!(name: "Alex Chen", role: "Junior Mechanic")
mechanic_jordan = Mechanic.create!(name: "Jordan Taylor", role: "Wheel Specialist")
counter_pat = Mechanic.create!(name: "Pat Morgan", role: "Counter Staff")


puts "Seeding Services..."
s_flat          = Service.create!(name: "Flat Tyre Repair", default_price: 20.00, active: true)
s_chain         = Service.create!(name: "Chain Replacement", default_price: 25.00, active: true)
s_shifting      = Service.create!(name: "Derailleur / Shifting Adjustment", default_price: 30.00, active: true)
s_wheel_true    = Service.create!(name: "Wheel True (Straightening)", default_price: 35.00, active: true)
s_brake_cable   = Service.create!(name: "Brake Cable & Housing Replacement", default_price: 35.00, active: true)
s_bleed         = Service.create!(name: "Hydraulic Brake Bleed", default_price: 40.00, active: true)
s_headset       = Service.create!(name: "Headset Service & Adjustment", default_price: 45.00, active: true)
s_bottom_b      = Service.create!(name: "Bottom Bracket Service", default_price: 50.00, active: true)
s_hydro_line    = Service.create!(name: "Hydraulic Line Replacement", default_price: 55.00, active: true)
s_drivetrain    = Service.create!(name: "Drivetrain Clean & Degrease", default_price: 60.00, active: true)
s_tuneup        = Service.create!(name: "Standard Tune-Up", default_price: 90.00, active: true)
s_assembly      = Service.create!(name: "Full Custom Bicycle Assembly", default_price: 200.00, active: true)
s_bar_tape      = Service.create!(name: "Handlebar Tape Installation", default_price: 25.00, active: true)
s_fender        = Service.create!(name: "Fender Set Installation", default_price: 30.00, active: true)
s_rack          = Service.create!(name: "Cargo Rack Installation", default_price: 25.00, active: true)
s_tubeless      = Service.create!(name: "Tubeless Setup (Per Wheel)", default_price: 40.00, active: true)
s_fork_service  = Service.create!(name: "Suspension Fork Lower Service", default_price: 85.00, active: true)
s_spoke_replace = Service.create!(name: "Spoke Replacement & True", default_price: 45.00, active: true)
s_brake_pad     = Service.create!(name: "Brake Pad Installation", default_price: 20.00, active: true)
s_overhaul      = Service.create!(name: "Complete Overhaul & Detail", default_price: 250.00, active: true)
s_legacy_check  = Service.create!(name: "Vintage Restoration Assessment", default_price: 75.00, active: false)


puts "Seeding Customers..."
c1  = Customer.create!(name: "Eleanor Vance", phone: "555-0101")
c2  = Customer.create!(name: "Marcus Holloway", phone: "555-0102")
c3  = Customer.create!(name: "Sophia Rodriguez", phone: "555-0103")
c4  = Customer.create!(name: "David Kim", phone: "555-0104") # Multiple bikes owner
c5  = Customer.create!(name: "Hannah Abbott", phone: "555-0105")
c6  = Customer.create!(name: "Liam O'Connor", phone: "555-0106")
c7  = Customer.create!(name: "Chloe Bennett", phone: "555-0107")
c8  = Customer.create!(name: "Tariq Al-Mansoor", phone: "555-0108")
c9  = Customer.create!(name: "Maya Lin", phone: "555-0109")
c10 = Customer.create!(name: "Carlos Mendez", phone: "555-0110")
c11 = Customer.create!(name: "Brenda Walsh", phone: "555-0111") # Customer with NO repairs


puts "Seeding Bikes..."
# same model
b1_giant1 = Bike.create!(make: "Giant", model: "Escape 3", color: "Blue", serial_number: "SN-GIANT-2024-001", customer_id: c1.id)
b2_giant2 = Bike.create!(make: "Giant", model: "Escape 3", color: "Blue", serial_number: "SN-GIANT-2024-002", customer_id: c2.id)

# same owner
b3_david_road = Bike.create!(make: "Specialized", model: "Allez", color: "Red", serial_number: "SN-SPEC-88219", customer_id: c4.id)
b4_david_mtb  = Bike.create!(make: "Trek", model: "Marlin 7", color: "Matte Black", serial_number: "SN-TREK-99120", customer_id: c4.id)

b5  = Bike.create!(make: "Cannondale", model: "Quick 4", color: "Sage Green", serial_number: "SN-CANN-33411", customer_id: c3.id)
b6  = Bike.create!(make: "Surly", model: "Disc Trucker", color: "Dark Blue", serial_number: "SN-SURL-55214", customer_id: c5.id)
b7  = Bike.create!(make: "Brodie", model: "Romulus", color: "Silver", serial_number: "SN-BROD-11928", customer_id: c6.id)
b8  = Bike.create!(make: "Kona", model: "Dew Deluxe", color: "Yellow", serial_number: "SN-KONA-77281", customer_id: c7.id)
b9  = Bike.create!(make: "Norco", model: "Search XR", color: "Charcoal", serial_number: "SN-NORC-66392", customer_id: c8.id)
b10 = Bike.create!(make: "Marin", model: "Fairfax 1", color: "Gloss Black", serial_number: "SN-MARI-44102", customer_id: c9.id)
b11 = Bike.create!(make: "Santa Cruz", model: "Chameleon", color: "Purple", serial_number: "SN-SANT-00291", customer_id: c10.id)
b12 = Bike.create!(make: "Fuji", model: "Feather", color: "White", serial_number: "SN-FUJI-33291", customer_id: c3.id)

# Bike that has never been in for a repair
b13 = Bike.create!(make: "Public", model: "M11 Deluxe", color: "Teal", serial_number: "SN-PUBL-00512", customer_id: c1.id)


puts "Seeding Repair Orders and Line Items..."

today = Date.today
now   = Time.current

# 1. Dropped Off
ro1 = RepairOrder.create!(
  bike_id: b1_giant1.id,
  mechanic_id: nil,
  status: "Dropped Off",
  promised_on: today + 3.days
)
RepairLineItem.create!(repair_order_id: ro1.id, service_id: s_flat.id, charged_price: 20.00)

# 2. Awaiting Estimate Approval
ro2 = RepairOrder.create!(
  bike_id: b2_giant2.id,
  mechanic_id: mechanic_alex.id,
  status: "Awaiting Estimate Approval",
  promised_on: today + 2.days,
  quoted_at: now - 4.hours,
  quote_accepted: nil
)
RepairLineItem.create!(repair_order_id: ro2.id, service_id: s_tuneup.id, charged_price: 90.00)
RepairLineItem.create!(repair_order_id: ro2.id, service_id: s_chain.id, charged_price: 25.00)

# 3. In Progress
ro3 = RepairOrder.create!(
  bike_id: b3_david_road.id,
  mechanic_id: mechanic_sam.id,
  status: "In Progress",
  promised_on: today + 1.day,
  quoted_at: now - 1.day,
  quote_accepted: true
)
RepairLineItem.create!(repair_order_id: ro3.id, service_id: s_bleed.id, charged_price: 40.00)
RepairLineItem.create!(repair_order_id: ro3.id, service_id: s_brake_pad.id, charged_price: 20.00)

# 4. Ready for Pickup
ro4 = RepairOrder.create!(
  bike_id: b5.id,
  mechanic_id: mechanic_jordan.id,
  status: "Ready for Pickup",
  promised_on: today,
  quoted_at: now - 2.days,
  quote_accepted: true,
  completed_at: now - 2.hours
)
RepairLineItem.create!(repair_order_id: ro4.id, service_id: s_wheel_true.id, charged_price: 35.00)

# ----------------------------------------------------------------------
# 5. Picked Up
ro5 = RepairOrder.create!(
  bike_id: b6.id,
  mechanic_id: mechanic_sam.id,
  status: "Picked Up",
  created_at: now - 5.days,
  promised_on: today - 3.days,
  quoted_at: now - 5.days,
  quote_accepted: true,
  completed_at: now - 4.days,
  picked_up_at: now - 3.days
)
RepairLineItem.create!(repair_order_id: ro5.id, service_id: s_drivetrain.id, charged_price: 60.00)

# ----------------------------------------------------------------------
# 6. SPECIAL CASE: Overdue repair
ro6 = RepairOrder.create!(
  bike_id: b7.id,
  mechanic_id: mechanic_alex.id,
  status: "In Progress",
  created_at: now - 4.days,
  promised_on: today - 2.days,
  quoted_at: now - 4.days,
  quote_accepted: true
)
RepairLineItem.create!(repair_order_id: ro6.id, service_id: s_fork_service.id, charged_price: 85.00)

# 7. SPECIAL CASE: Came in and went out the SAME DAY
ro7 = RepairOrder.create!(
  bike_id: b8.id,
  mechanic_id: mechanic_jordan.id,
  status: "Picked Up",
  created_at: now - 1.day,
  promised_on: today - 1.day,
  quoted_at: nil,
  quote_accepted: true,
  completed_at: (now - 1.day) + 2.hours,
  picked_up_at: (now - 1.day) + 5.hours
)
# Includes DISCOUNTED line item ($15.00 charged instead of $20.00)
RepairLineItem.create!(repair_order_id: ro7.id, service_id: s_flat.id, charged_price: 15.00)

# 8. SPECIAL CASE: Customer rejected estimate
ro8 = RepairOrder.create!(
  bike_id: b9.id,
  mechanic_id: mechanic_alex.id,
  status: "Ready for Pickup",
  promised_on: today + 1.day,
  quoted_at: now - 1.day,
  quote_accepted: false,
  completed_at: now - 12.hours
)
RepairLineItem.create!(repair_order_id: ro8.id, service_id: s_overhaul.id, charged_price: 250.00)

# 9. SPECIAL CASE: Bike with MULTIPLE repairs on different dates (First Repair)
ro9_old = RepairOrder.create!(
  bike_id: b4_david_mtb.id,
  mechanic_id: mechanic_sam.id,
  status: "Picked Up",
  created_at: now - 62.days,
  promised_on: today - 60.days,
  quoted_at: now - 62.days,
  quote_accepted: true,
  completed_at: now - 60.days,
  picked_up_at: now - 59.days
)
RepairLineItem.create!(repair_order_id: ro9_old.id, service_id: s_tuneup.id, charged_price: 90.00)

# 10. SPECIAL CASE: Bike with MULTIPLE repairs on different dates (Second Repair - Current)
ro10_new = RepairOrder.create!(
  bike_id: b4_david_mtb.id,
  mechanic_id: mechanic_jordan.id,
  status: "In Progress",
  promised_on: today + 2.days,
  quoted_at: now - 6.hours,
  quote_accepted: true
)
RepairLineItem.create!(repair_order_id: ro10_new.id, service_id: s_tubeless.id, charged_price: 40.00)

# 11. SPECIAL CASE: Repair before last January with HISTORICAL prices
# (Charged price differs from current list price)
ro11_historical = RepairOrder.create!(
  bike_id: b10.id,
  mechanic_id: mechanic_sam.id,
  status: "Picked Up",
  created_at: Time.zone.local(2025, 11, 14, 9, 0),
  promised_on: Date.new(2025, 11, 15),
  quoted_at: Time.zone.local(2025, 11, 14, 10, 0),
  quote_accepted: true,
  completed_at: Time.zone.local(2025, 11, 15, 16, 0),
  picked_up_at: Time.zone.local(2025, 11, 16, 11, 0)
)
# Charged $75 last year, while current default_price on Service is $90
RepairLineItem.create!(repair_order_id: ro11_historical.id, service_id: s_tuneup.id, charged_price: 75.00)
# Charged $20 last year, current default_price is $25
RepairLineItem.create!(repair_order_id: ro11_historical.id, service_id: s_chain.id, charged_price: 20.00)

# 12. Dropped Off (Multi-item job)
ro12 = RepairOrder.create!(
  bike_id: b11.id,
  mechanic_id: nil,
  status: "Dropped Off",
  promised_on: today + 4.days
)
RepairLineItem.create!(repair_order_id: ro12.id, service_id: s_shifting.id, charged_price: 30.00)
RepairLineItem.create!(repair_order_id: ro12.id, service_id: s_brake_cable.id, charged_price: 35.00)
RepairLineItem.create!(repair_order_id: ro12.id, service_id: s_bar_tape.id, charged_price: 25.00)

# 13. Picked Up (Accessory installations)
ro13 = RepairOrder.create!(
  bike_id: b12.id,
  mechanic_id: mechanic_alex.id,
  status: "Picked Up",
  created_at: now - 12.days,
  promised_on: today - 10.days,
  quoted_at: now - 12.days,
  quote_accepted: true,
  completed_at: now - 10.days,
  picked_up_at: now - 9.days
)
RepairLineItem.create!(repair_order_id: ro13.id, service_id: s_fender.id, charged_price: 30.00)
RepairLineItem.create!(repair_order_id: ro13.id, service_id: s_rack.id, charged_price: 25.00)

# 14. In Progress (Complex bottom bracket + headset service)
ro14 = RepairOrder.create!(
  bike_id: b1_giant1.id,
  mechanic_id: mechanic_sam.id,
  status: "In Progress",
  promised_on: today + 1.day,
  quoted_at: now - 1.day,
  quote_accepted: true
)
RepairLineItem.create!(repair_order_id: ro14.id, service_id: s_bottom_b.id, charged_price: 50.00)
RepairLineItem.create!(repair_order_id: ro14.id, service_id: s_headset.id, charged_price: 45.00)

# ----------------------------------------------------------------------
# 15. Ready for Pickup (Custom Assembly)
ro15 = RepairOrder.create!(
  bike_id: b3_david_road.id,
  mechanic_id: mechanic_jordan.id,
  status: "Ready for Pickup",
  promised_on: today,
  quoted_at: now - 3.days,
  quote_accepted: true,
  completed_at: now - 1.hour
)
RepairLineItem.create!(repair_order_id: ro15.id, service_id: s_assembly.id, charged_price: 200.00)

puts "Successfully seeded database!"