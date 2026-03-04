# frozen_string_literal: true

require "test_helper"

class StaffMonthlyResultsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @representative_role = Role.create!(name: "代表", display_order: 1)
    @member_role = Role.create!(name: "千人将", display_order: 2)

    @active_member = create_user(
      email: "s7-active-member@example.com",
      system_role: "member",
      is_active: true,
      role: @member_role
    )
    @inactive_member = create_user(
      email: "s7-inactive-member@example.com",
      system_role: "member",
      is_active: false,
      role: @member_role
    )
    @active_admin = create_user(
      email: "s7-active-admin@example.com",
      system_role: "admin",
      is_active: true,
      role: @member_role
    )
    @another_active_member = create_user(
      email: "s7-another-member@example.com",
      system_role: "member",
      is_active: true,
      role: @member_role
    )
    @active_representative = create_user(
      email: "s8-active-representative@example.com",
      system_role: "admin",
      is_active: true,
      role: @representative_role
    )
    @inactive_representative = create_user(
      email: "s8-inactive-representative@example.com",
      system_role: "admin",
      is_active: false,
      role: @representative_role
    )
  end

  test "bulk upsert creates and updates staff monthly results" do
    existing = StaffMonthlyResult.create!(
      user: @active_member,
      work_month: Date.new(2026, 1, 1),
      salary: 300_000,
      legal_welfare: 48_000,
      welfare: 12_000,
      bonus: 0
    )

    assert_difference("StaffMonthlyResult.count", 1) do
      post "/staff_monthly_results/bulk_upsert", params: {
        entries: [
          {
            user_id: @active_member.id,
            work_month: "2026-01",
            salary: 320_000,
            legal_welfare: 51_000,
            welfare: 12_340,
            bonus: 71_000
          },
          {
            user_id: @another_active_member.id,
            work_month: "2026-01",
            salary: 280_000,
            legal_welfare: 44_000,
            welfare: 11_110,
            bonus: 0
          }
        ]
      }
    end

    assert_redirected_to master_path
    assert_equal 320_000, existing.reload.salary.to_i
    assert_equal 51_000, existing.reload.legal_welfare.to_i
    assert_equal 12_340, existing.reload.welfare.to_i
    assert_equal 71_000, existing.reload.bonus.to_i
  end

  test "bulk upsert rejects empty entries" do
    assert_no_difference("StaffMonthlyResult.count") do
      post "/staff_monthly_results/bulk_upsert", params: { entries: [] }
    end

    assert_redirected_to master_path
  end

  test "bulk upsert rejects blank entries payload" do
    assert_no_difference("StaffMonthlyResult.count") do
      post "/staff_monthly_results/bulk_upsert", params: { entries: ["", "   ", nil] }
    end

    assert_redirected_to master_path
  end

  test "bulk upsert rejects duplicated user month in payload" do
    assert_no_difference("StaffMonthlyResult.count") do
      post "/staff_monthly_results/bulk_upsert", params: {
        entries: [
          { user_id: @active_member.id, work_month: "2026-01", salary: 300_000, legal_welfare: 48_000, welfare: 12_000, bonus: 0 },
          { user_id: @active_member.id, work_month: "2026-01", salary: 310_000, legal_welfare: 49_000, welfare: 12_010, bonus: 1_000 }
        ]
      }
    end

    assert_redirected_to master_path
  end

  test "bulk upsert rejects invalid month format" do
    assert_no_difference("StaffMonthlyResult.count") do
      post "/staff_monthly_results/bulk_upsert", params: {
        entries: [
          { user_id: @active_member.id, work_month: "2026-13", salary: 300_000, legal_welfare: 48_000, welfare: 12_000, bonus: 0 }
        ]
      }
    end

    assert_redirected_to master_path
  end

  test "bulk upsert rejects inactive user" do
    assert_no_difference("StaffMonthlyResult.count") do
      post "/staff_monthly_results/bulk_upsert", params: {
        entries: [
          { user_id: @inactive_member.id, work_month: "2026-01", salary: 300_000, legal_welfare: 48_000, welfare: 12_000, bonus: 0 }
        ]
      }
    end

    assert_redirected_to master_path
  end

  test "bulk upsert rejects admin user" do
    assert_no_difference("StaffMonthlyResult.count") do
      post "/staff_monthly_results/bulk_upsert", params: {
        entries: [
          { user_id: @active_admin.id, work_month: "2026-01", salary: 300_000, legal_welfare: 48_000, welfare: 12_000, bonus: 0 }
        ]
      }
    end

    assert_redirected_to master_path
  end

  test "bulk upsert rejects step violation values" do
    assert_no_difference("StaffMonthlyResult.count") do
      post "/staff_monthly_results/bulk_upsert", params: {
        entries: [
          { user_id: @active_member.id, work_month: "2026-01", salary: 300_001, legal_welfare: 48_000, welfare: 12_015, bonus: 0 }
        ]
      }
    end

    assert_redirected_to master_path
  end

  test "bulk upsert rejects non integer values" do
    assert_no_difference("StaffMonthlyResult.count") do
      post "/staff_monthly_results/bulk_upsert", params: {
        entries: [
          { user_id: @active_member.id, work_month: "2026-01", salary: "abc", legal_welfare: 48_000, welfare: 12_000, bonus: 0 }
        ]
      }
    end

    assert_redirected_to master_path
  end

  test "bulk upsert is atomic when payload includes invalid row" do
    assert_no_difference("StaffMonthlyResult.count") do
      post "/staff_monthly_results/bulk_upsert", params: {
        entries: [
          { user_id: @active_member.id, work_month: "2026-01", salary: 300_000, legal_welfare: 48_000, welfare: 12_000, bonus: 0 },
          { user_id: @another_active_member.id, work_month: "2026-02", salary: 301_001, legal_welfare: 48_000, welfare: 12_010, bonus: 0 }
        ]
      }
    end

    assert_redirected_to master_path
    assert_nil StaffMonthlyResult.find_by(user_id: @active_member.id, work_month: Date.new(2026, 1, 1))
  end

  test "bulk upsert officers creates and updates staff monthly results" do
    another_representative = create_user(
      email: "s8-another-representative@example.com",
      system_role: "admin",
      is_active: true,
      role: @representative_role
    )
    existing = StaffMonthlyResult.create!(
      user: @active_representative,
      work_month: Date.new(2026, 1, 1),
      salary: 500_000,
      legal_welfare: 80_000,
      welfare: 15_000,
      bonus: 90_000
    )

    assert_difference("StaffMonthlyResult.count", 1) do
      post "/staff_monthly_results/bulk_upsert_officers", params: {
        entries: [
          {
            user_id: @active_representative.id,
            work_month: "2026-01",
            salary: 510_000,
            legal_welfare: 82_000,
            welfare: 15_020,
            bonus: 95_000
          },
          {
            user_id: another_representative.id,
            work_month: "2026-01",
            salary: 520_000,
            legal_welfare: 83_000,
            welfare: 16_000,
            bonus: 100_000
          }
        ]
      }
    end

    assert_redirected_to master_path
    assert_equal 510_000, existing.reload.salary.to_i
    assert_equal 82_000, existing.reload.legal_welfare.to_i
    assert_equal 15_020, existing.reload.welfare.to_i
    assert_equal 95_000, existing.reload.bonus.to_i
  end

  test "bulk upsert officers rejects empty entries" do
    assert_no_difference("StaffMonthlyResult.count") do
      post "/staff_monthly_results/bulk_upsert_officers", params: { entries: [] }
    end

    assert_redirected_to master_path
  end

  test "bulk upsert officers rejects blank entries payload" do
    assert_no_difference("StaffMonthlyResult.count") do
      post "/staff_monthly_results/bulk_upsert_officers", params: { entries: ["", "   ", nil] }
    end

    assert_redirected_to master_path
  end

  test "bulk upsert officers rejects duplicated user month in payload" do
    assert_no_difference("StaffMonthlyResult.count") do
      post "/staff_monthly_results/bulk_upsert_officers", params: {
        entries: [
          { user_id: @active_representative.id, work_month: "2026-01", salary: 500_000, legal_welfare: 80_000, welfare: 15_000, bonus: 90_000 },
          { user_id: @active_representative.id, work_month: "2026-01", salary: 510_000, legal_welfare: 82_000, welfare: 15_010, bonus: 95_000 }
        ]
      }
    end

    assert_redirected_to master_path
  end

  test "bulk upsert officers rejects invalid month format" do
    assert_no_difference("StaffMonthlyResult.count") do
      post "/staff_monthly_results/bulk_upsert_officers", params: {
        entries: [
          { user_id: @active_representative.id, work_month: "2026-13", salary: 500_000, legal_welfare: 80_000, welfare: 15_000, bonus: 90_000 }
        ]
      }
    end

    assert_redirected_to master_path
  end

  test "bulk upsert officers rejects member user" do
    assert_no_difference("StaffMonthlyResult.count") do
      post "/staff_monthly_results/bulk_upsert_officers", params: {
        entries: [
          { user_id: @active_member.id, work_month: "2026-01", salary: 500_000, legal_welfare: 80_000, welfare: 15_000, bonus: 90_000 }
        ]
      }
    end

    assert_redirected_to master_path
  end

  test "bulk upsert officers rejects non representative admin user" do
    assert_no_difference("StaffMonthlyResult.count") do
      post "/staff_monthly_results/bulk_upsert_officers", params: {
        entries: [
          { user_id: @active_admin.id, work_month: "2026-01", salary: 500_000, legal_welfare: 80_000, welfare: 15_000, bonus: 90_000 }
        ]
      }
    end

    assert_redirected_to master_path
  end

  test "bulk upsert officers rejects inactive representative user" do
    assert_no_difference("StaffMonthlyResult.count") do
      post "/staff_monthly_results/bulk_upsert_officers", params: {
        entries: [
          { user_id: @inactive_representative.id, work_month: "2026-01", salary: 500_000, legal_welfare: 80_000, welfare: 15_000, bonus: 90_000 }
        ]
      }
    end

    assert_redirected_to master_path
  end

  test "bulk upsert officers rejects step violation values" do
    assert_no_difference("StaffMonthlyResult.count") do
      post "/staff_monthly_results/bulk_upsert_officers", params: {
        entries: [
          { user_id: @active_representative.id, work_month: "2026-01", salary: 500_001, legal_welfare: 80_000, welfare: 15_000, bonus: 90_000 }
        ]
      }
    end

    assert_redirected_to master_path
  end

  test "bulk upsert officers is atomic when payload includes invalid row" do
    another_representative = create_user(
      email: "s8-atomic-representative@example.com",
      system_role: "admin",
      is_active: true,
      role: @representative_role
    )

    assert_no_difference("StaffMonthlyResult.count") do
      post "/staff_monthly_results/bulk_upsert_officers", params: {
        entries: [
          { user_id: @active_representative.id, work_month: "2026-01", salary: 500_000, legal_welfare: 80_000, welfare: 15_000, bonus: 90_000 },
          { user_id: another_representative.id, work_month: "2026-02", salary: 500_001, legal_welfare: 80_000, welfare: 15_000, bonus: 90_000 }
        ]
      }
    end

    assert_redirected_to master_path
    assert_nil StaffMonthlyResult.find_by(user_id: @active_representative.id, work_month: Date.new(2026, 1, 1))
  end

  private

  def create_user(email:, system_role:, is_active:, role: nil)
    User.create!(
      name: email.split("@").first,
      email: email,
      password: "password123",
      password_confirmation: "password123",
      system_role: system_role,
      is_active: is_active,
      role: role
    )
  end
end
