require "test_helper"

class RepairPolicyTest < ActiveSupport::TestCase
  setup do
    @marco = Employee.create!(name: "Marco", role: "mechanic")
    @vale = Employee.create!(name: "Vale", role: "mechanic")
    bike = Bike.create!(customer: Customer.create!(name: "Ana", phone: "1"), make: "Trek", model: "FX", color: "Red", serial_number: "S-1")
    @own_open = Repair.create!(bike: bike, mechanic: @marco, reported_problem: "a")
    service = Service.create!(name: "Flat", price: 8000)
    @own_done = Repair.new(bike: bike, mechanic: @marco, reported_problem: "b", status: :completed)
    @own_done.repair_line_items.build(service: service, charged_price: 8000)
    @own_done.save!
    @other = Repair.create!(bike: bike, mechanic: @vale, reported_problem: "c")
    @unassigned = Repair.create!(bike: bike, reported_problem: "d")

    @owner = User.create!(email_address: "o@x.cl", password: "long-enough", role: :owner)
    @counter = User.create!(email_address: "c@x.cl", password: "long-enough", role: :counter)
    @mechanic = User.create!(email_address: "m@x.cl", password: "long-enough", role: :mechanic, employee: @marco)
    @loose = User.create!(email_address: "l@x.cl", password: "long-enough")
  end

  def policy(user, record) = RepairPolicy.new(user, record)
  def scope(user) = RepairPolicy::Scope.new(user, Repair).resolve

  test "the scope and show? agree for every account and every repair" do
    [ @owner, @counter, @mechanic, @loose, nil ].each do |user|
      Repair.find_each do |repair|
        assert_equal policy(user, repair).show?, scope(user).include?(repair),
          "#{user&.email_address || 'visitor'} on repair #{repair.id}"
      end
    end
  end

  test "a mechanic reads only their own repairs; one with no staff member reads none" do
    assert_equal [ @own_open, @own_done ].sort, scope(@mechanic).to_a.sort
    assert_empty scope(@loose)
    assert_not policy(@loose, @unassigned).show?
  end

  test "editing" do
    assert policy(@owner, @own_done).update?
    assert policy(@counter, @own_open).update?
    assert_not policy(@counter, @own_done).update?
    assert policy(@mechanic, @own_open).update?
    assert_not policy(@mechanic, @own_done).update?
    assert_not policy(@mechanic, @other).update?
  end

  test "taking in and deleting" do
    assert policy(@owner, Repair).create?
    assert policy(@counter, Repair).create?
    assert_not policy(@mechanic, Repair).create?
    assert policy(@owner, @own_open).destroy?
    assert_not policy(@counter, @own_open).destroy?
    assert_not policy(@mechanic, @own_open).destroy?
  end

  test "a mechanic writes the state, the diagnosis and new photos only" do
    assert_equal [ :status, :diagnosis, { intake_photos: [] } ], policy(@mechanic, @own_open).permitted_attributes
    assert_includes policy(@counter, @own_open).permitted_attributes, :mechanic_id
    assert_empty policy(nil, @own_open).permitted_attributes
  end

  test "the base policy refuses everything" do
    base = ApplicationPolicy.new(@owner, @own_open)
    %i[index? show? create? new? update? edit? destroy?].each { |action| assert_not base.public_send(action), action }
    assert_empty ApplicationPolicy::Scope.new(@owner, Repair).resolve
  end
end
