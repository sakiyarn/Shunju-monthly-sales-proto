# frozen_string_literal: true

require "test_helper"

class BillingWorkLogsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @active_project = Project.create!(name: "進行案件", is_active: true)
    @closed_project = Project.create!(name: "終了案件", is_active: false)
    @user = create_user("billing-work-log-controller@example.com")
    @another_user = create_user("billing-work-log-controller-2@example.com")

    ProjectMember.create!(project: @active_project, user: @user, default_billing_rate: 7_000)
    ProjectMember.create!(project: @active_project, user: @another_user, default_billing_rate: 8_000)
  end

  test "bulk upsert creates and updates billing work logs" do
    existing = BillingWorkLog.create!(
      project: @active_project,
      user: @user,
      work_month: Date.new(2026, 1, 1),
      billed_hours: 80,
      billing_rate: 6_000
    )

    assert_difference("BillingWorkLog.count", 1) do
      post "/billing_work_logs/bulk_upsert", params: {
        project_id: @active_project.id,
        entries: [
          { user_id: @user.id, work_month: "2026-01", billed_hours: 120, billing_rate: 7_000 },
          { user_id: @another_user.id, work_month: "2026-01", billed_hours: 100, billing_rate: 8_000 }
        ]
      }
    end

    assert_redirected_to master_path
    assert_equal 120, existing.reload.billed_hours.to_i
    assert_equal 7_000, existing.reload.billing_rate.to_i
  end

  test "bulk upsert rejects closed project" do
    ProjectMember.create!(project: @closed_project, user: @user, default_billing_rate: 7_000)

    assert_no_difference("BillingWorkLog.count") do
      post "/billing_work_logs/bulk_upsert", params: {
        project_id: @closed_project.id,
        entries: [
          { user_id: @user.id, work_month: "2026-01", billed_hours: 120, billing_rate: 7_000 }
        ]
      }
    end

    assert_redirected_to master_path
  end

  test "bulk upsert rejects invalid month format" do
    assert_no_difference("BillingWorkLog.count") do
      post "/billing_work_logs/bulk_upsert", params: {
        project_id: @active_project.id,
        entries: [
          { user_id: @user.id, work_month: "2026-13", billed_hours: 120, billing_rate: 7_000 }
        ]
      }
    end

    assert_redirected_to master_path
  end

  test "bulk upsert rejects empty entries" do
    assert_no_difference("BillingWorkLog.count") do
      post "/billing_work_logs/bulk_upsert", params: {
        project_id: @active_project.id,
        entries: []
      }
    end

    assert_redirected_to master_path
  end

  test "bulk upsert rejects blank entries payload" do
    assert_no_difference("BillingWorkLog.count") do
      post "/billing_work_logs/bulk_upsert", params: {
        project_id: @active_project.id,
        entries: [ "", "   ", nil ]
      }
    end

    assert_redirected_to master_path
  end

  test "bulk upsert rejects duplicated user month in payload" do
    assert_no_difference("BillingWorkLog.count") do
      post "/billing_work_logs/bulk_upsert", params: {
        project_id: @active_project.id,
        entries: [
          { user_id: @user.id, work_month: "2026-01", billed_hours: 120, billing_rate: 7_000 },
          { user_id: @user.id, work_month: "2026-01", billed_hours: 100, billing_rate: 7_000 }
        ]
      }
    end

    assert_redirected_to master_path
  end

  test "bulk upsert rejects missing project" do
    assert_no_difference("BillingWorkLog.count") do
      post "/billing_work_logs/bulk_upsert", params: {
        project_id: -1,
        entries: [
          { user_id: @user.id, work_month: "2026-01", billed_hours: 120, billing_rate: 7_000 }
        ]
      }
    end

    assert_redirected_to master_path
  end

  private

  def create_user(email)
    User.create!(
      name: email.split("@").first,
      email: email,
      password: "password123",
      password_confirmation: "password123",
      system_role: "member",
      is_active: true
    )
  end
end
