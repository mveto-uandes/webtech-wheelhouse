require "test_helper"

class ResourcePoliciesTest < ActiveSupport::TestCase
  setup do
    @owner = User.new(role: :owner)
    @counter = User.new(role: :counter)
    @mechanic = User.new(role: :mechanic)
  end

  def allowed(policy_class, actions, record = Object.new)
    [ @owner, @counter, @mechanic ].map { |user| actions.all? { |a| policy_class.new(user, record).public_send(a) } }
  end

  test "services: the owner writes, everyone reads, visitors included" do
    assert_equal [ true, false, false ], allowed(ServicePolicy, %i[new? create? edit? update? destroy?])
    assert_equal [ true, true, true ], allowed(ServicePolicy, %i[index? show?])
    assert ServicePolicy.new(nil, Service).index?
  end

  test "staff: the owner writes, every account reads" do
    assert_equal [ true, false, false ], allowed(EmployeePolicy, %i[new? create? edit? update? destroy?])
    assert_equal [ true, true, true ], allowed(EmployeePolicy, %i[index? show?])
  end

  test "customers and bikes: the counter all but delete, mechanics nothing" do
    [ CustomerPolicy, BikePolicy ].each do |policy_class|
      assert_equal [ true, true, false ], allowed(policy_class, %i[index? show? new? create? edit? update?])
      assert_equal [ true, false, false ], allowed(policy_class, %i[destroy?])
    end
  end

  test "payments: the owner and the counter read" do
    assert_equal [ true, true, false ], allowed(PaymentPolicy, %i[index? show?])
  end
end
