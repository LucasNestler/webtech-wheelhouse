require "test_helper"

class UserTest < ActiveSupport::TestCase
  def build_user(**attributes)
    User.new({ email_address: "ana@wheelhouse.cl", password: "long-enough-1", password_confirmation: "long-enough-1" }.merge(attributes))
  end

  def insert_raw(email)
    now = Time.current
    User.insert!({ email_address: email, password_digest: "x", created_at: now, updated_at: now })
  end

  test "stores a digest and no column holds a password" do
    user = build_user
    user.save!

    assert user.password_digest.present?
    assert_not_includes User.column_names, "password"
    assert_equal [ "password_digest" ], User.column_names.grep(/passw/)
  end

  test "the default role is the one the decision names, and every role is known" do
    assert build_user.role_mechanic?
    assert_equal %w[ owner mechanic counter ].sort, User.roles.keys.sort
    assert_equal false, User.columns_hash["role"].null
  end

  test "an email address is required and has a format" do
    [ nil, "", "ana", "ana@", "@wheelhouse.cl", "ana@wheelhouse", "a b@wheelhouse.cl" ].each do |address|
      user = build_user(email_address: address)
      assert_not user.valid?, address.inspect
      assert user.errors[:email_address].any?
    end
  end

  test "addresses differing only in case are the same account" do
    build_user(email_address: "Ana@Wheelhouse.cl").save!

    assert_equal "ana@wheelhouse.cl", User.last.email_address
    assert_not build_user(email_address: "ANA@wheelhouse.CL").valid?
    assert_equal User.last, User.find_by(email_address: " ANA@WHEELHOUSE.cl ")
  end

  test "the database refuses a duplicate address whatever its case" do
    insert_raw("ana@wheelhouse.cl")

    assert_raises(ActiveRecord::RecordNotUnique) { insert_raw("Ana@Wheelhouse.cl") }
  end

  test "a short password is refused and the message states the minimum" do
    user = build_user(password: "123456789", password_confirmation: "123456789")

    assert_not user.valid?
    assert_includes user.errors[:password].join, User::PASSWORD_MINIMUM_LENGTH.to_s
    assert_operator User::PASSWORD_MINIMUM_LENGTH, :>=, 10
  end

  test "a password needs its confirmation" do
    assert_not build_user(password_confirmation: nil).valid?
    assert_not build_user(password_confirmation: "something-else").valid?
  end

  test "an existing account can be saved without touching its password" do
    assert users(:one).update(email_address: "renamed@example.com")
  end

  test "an account may belong to no member of the staff, or to one that has no other" do
    sam = Mechanic.create!(name: "Sam", role: "Lead")

    assert build_user(email_address: "a@wheelhouse.cl").save
    assert build_user(email_address: "b@wheelhouse.cl").save
    assert build_user(email_address: "c@wheelhouse.cl", mechanic: sam).save
    assert_raises(ActiveRecord::RecordNotUnique) do
      build_user(email_address: "d@wheelhouse.cl", mechanic: sam).save
    end
  end

  test "the database refuses a member of the staff that does not exist" do
    assert_raises(ActiveRecord::InvalidForeignKey) do
      users(:one).update_column(:mechanic_id, 0)
    end
  end

  test "display name is the member of the staff, or the address" do
    assert_equal "ana@wheelhouse.cl", build_user.display_name
    assert_equal "Sam", build_user(mechanic: Mechanic.new(name: "Sam")).display_name
  end
end
