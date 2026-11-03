require "test_helper"

# The table of docs/permissions.md, read back from the policies.
class PoliciesTest < ActiveSupport::TestCase
  ACTIONS = %i[ index? show? new? create? edit? update? destroy? ].freeze

  setup do
    @sam = Mechanic.new(id: 1, name: "Sam", role: "Lead")
    @owner = User.new(role: :owner)
    @counter = User.new(role: :counter)
    @mechanic = User.new(role: :mechanic, mechanic: @sam, mechanic_id: 1)
    @nobody_mechanic = User.new(role: :mechanic)
  end

  def allowed(policy_class, user, record)
    policy = policy_class.new(user, record)
    ACTIONS.select { |action| policy.public_send(action) }
  end

  def repair(mechanic_id: nil, status: :in_progress)
    RepairOrder.new(mechanic_id: mechanic_id, status: status)
  end

  test "the base policy refuses everything and its scope is empty" do
    ACTIONS.each do |action|
      assert_not ApplicationPolicy.new(@owner, Service).public_send(action), action
    end
    assert_empty ApplicationPolicy.new(@owner, Service).permitted_attributes
    Service.create!(name: "Brakes", default_price: 5)
    assert_empty ApplicationPolicy::Scope.new(@owner, Service).resolve
  end

  test "services: the owner writes, everybody reads, visitors included" do
    assert_equal ACTIONS, allowed(ServicePolicy, @owner, Service)
    [ @counter, @mechanic, @nobody_mechanic, nil ].each do |user|
      assert_equal %i[ index? show? ], allowed(ServicePolicy, user, Service)
    end
  end

  test "staff: the owner writes, every account reads, visitors do not" do
    assert_equal ACTIONS, allowed(MechanicPolicy, @owner, Mechanic)
    [ @counter, @mechanic, @nobody_mechanic ].each do |user|
      assert_equal %i[ index? show? ], allowed(MechanicPolicy, user, Mechanic)
    end
    assert_empty allowed(MechanicPolicy, nil, Mechanic)
  end

  test "customers and bikes: everything, all but deleting, or no access" do
    [ CustomerPolicy, BikePolicy ].each do |policy|
      assert_equal ACTIONS, allowed(policy, @owner, Object)
      assert_equal ACTIONS - [ :destroy? ], allowed(policy, @counter, Object)
      assert_empty allowed(policy, @mechanic, Object)
      assert_empty allowed(policy, @nobody_mechanic, Object)
      assert_empty allowed(policy, nil, Object)
    end
  end

  test "repairs: the owner does everything, handed back or not" do
    [ repair, repair(status: :picked_up), repair(mechanic_id: 1) ].each do |record|
      assert_equal ACTIONS, allowed(RepairOrderPolicy, @owner, record)
      assert RepairOrderPolicy.new(@owner, record).remove_photo?
    end
  end

  test "repairs: the counter reads all, takes in, edits what is not handed back, never deletes" do
    assert_equal ACTIONS - [ :destroy? ], allowed(RepairOrderPolicy, @counter, repair)
    assert_equal %i[ index? show? new? create? ], allowed(RepairOrderPolicy, @counter, repair(status: :picked_up))
    assert RepairOrderPolicy.new(@counter, repair).remove_photo?
    assert_not RepairOrderPolicy.new(@counter, repair(status: :picked_up)).remove_photo?
  end

  test "repairs: a mechanic reads their own and edits them until they are handed back" do
    assert_equal %i[ index? show? edit? update? ], allowed(RepairOrderPolicy, @mechanic, repair(mechanic_id: 1))
    assert_equal %i[ index? show? ], allowed(RepairOrderPolicy, @mechanic, repair(mechanic_id: 1, status: :picked_up))
    assert_equal %i[ index? ], allowed(RepairOrderPolicy, @mechanic, repair(mechanic_id: 2))
    assert_equal %i[ index? ], allowed(RepairOrderPolicy, @mechanic, repair)
    assert_not RepairOrderPolicy.new(@mechanic, repair(mechanic_id: 1)).remove_photo?
  end

  test "repairs: a mechanic with no member of the staff has no repairs, not even unassigned ones" do
    assert_equal %i[ index? ], allowed(RepairOrderPolicy, @nobody_mechanic, repair)
    assert_equal %i[ index? ], allowed(RepairOrderPolicy, @nobody_mechanic, repair(mechanic_id: 1))
  end

  test "repairs: a visitor gets nothing" do
    assert_empty allowed(RepairOrderPolicy, nil, repair)
  end

  test "repairs: each role has its own list of attributes" do
    mechanic_list = RepairOrderPolicy.new(@mechanic, repair).permitted_attributes
    assert_equal RepairOrderPolicy::MECHANIC_ATTRIBUTES, mechanic_list
    assert_equal RepairOrderPolicy::FRONT_DESK_ATTRIBUTES, RepairOrderPolicy.new(@owner, repair).permitted_attributes
    assert_equal RepairOrderPolicy::FRONT_DESK_ATTRIBUTES, RepairOrderPolicy.new(@counter, repair).permitted_attributes

    assert_not_includes RepairOrderPolicy::FRONT_DESK_ATTRIBUTES, :taken_in_by_id
    assert_not_includes mechanic_list, :mechanic_id
  end

  test "pages: every account, and no visitor" do
    [ @owner, @counter, @mechanic, @nobody_mechanic ].each do |user|
      assert PagePolicy.new(user, :page).home?
    end
    assert_not PagePolicy.new(nil, :page).home?
  end

  test "no policy names a role in a string or reads the session, params or Current" do
    Rails.root.glob("app/policies/*.rb").each do |file|
      source = file.read
      User.roles.each_key { |role| assert_no_match(/["']#{role}["']/, source, file.basename.to_s) }
      assert_no_match(/\b(session|params|Current|cookies)\b/, source.gsub(/^\s*#.*$/, ""), file.basename.to_s)
    end
  end
end
