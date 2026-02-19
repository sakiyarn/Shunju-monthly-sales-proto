# frozen_string_literal: true

require "test_helper"

class BillingWorkLogTest < ActiveSupport::TestCase
  setup do
    @project = Project.create!(name: "案件A", is_active: true)
    @user = User.create!(
      name: "テストユーザー",
      email: "billing-work-log-model@example.com",
      password: "password123",
      password_confirmation: "password123",
      system_role: "member",
      is_active: true
    )
    ProjectMember.create!(project: @project, user: @user, default_billing_rate: 7_000)
  end

  test "is valid with boundary values" do
    log = BillingWorkLog.new(
      project: @project,
      user: @user,
      work_month: Date.new(2026, 2, 1),
      billed_hours: 999,
      billing_rate: 99_990
    )

    assert log.valid?
  end

  test "rejects invalid billed_hours" do
    [-1, 1_000, 10.5].each do |hours|
      log = BillingWorkLog.new(
        project: @project,
        user: @user,
        work_month: Date.new(2026, 2, 1),
        billed_hours: hours,
        billing_rate: 10
      )
      assert_not log.valid?
      assert log.errors[:billed_hours].present?
    end
  end

  test "rejects invalid billing_rate" do
    [-10, 100_000, 55.5, 555].each do |rate|
      log = BillingWorkLog.new(
        project: @project,
        user: @user,
        work_month: Date.new(2026, 2, 1),
        billed_hours: 100,
        billing_rate: rate
      )
      assert_not log.valid?
      assert log.errors[:billing_rate].present?
    end
  end

  test "rejects duplicate user project month" do
    BillingWorkLog.create!(
      project: @project,
      user: @user,
      work_month: Date.new(2026, 2, 1),
      billed_hours: 120,
      billing_rate: 7_000
    )

    duplicate = BillingWorkLog.new(
      project: @project,
      user: @user,
      work_month: Date.new(2026, 2, 1),
      billed_hours: 100,
      billing_rate: 6_000
    )

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:user_id], "はすでに存在します"
  end

  test "rejects user who is not assigned to project" do
    unassigned_user = User.create!(
      name: "未アサイン",
      email: "billing-work-log-unassigned@example.com",
      password: "password123",
      password_confirmation: "password123",
      system_role: "member",
      is_active: true
    )

    log = BillingWorkLog.new(
      project: @project,
      user: unassigned_user,
      work_month: Date.new(2026, 2, 1),
      billed_hours: 100,
      billing_rate: 6_000
    )

    assert_not log.valid?
    assert_includes log.errors[:user_id], "は案件にアサインされていません"
  end
end
