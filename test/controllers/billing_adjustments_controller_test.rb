# frozen_string_literal: true

require "test_helper"

class BillingAdjustmentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @role = Role.create!(name: "千人将", display_order: 1)
    @active_user = create_user("s10-active-user@example.com", is_active: true)
    @another_active_user = create_user("s10-another-active-user@example.com", is_active: true)
    @inactive_user = create_user("s10-inactive-user@example.com", is_active: false)
    @active_project = Project.create!(name: "進行案件S10", is_active: true)
    @another_active_project = Project.create!(name: "進行案件S10B", is_active: true)
    @closed_project = Project.create!(name: "終了案件S10", is_active: false)
  end

  test "bulk sync creates updates and deletes billing adjustments" do
    updating = BillingAdjustment.create!(
      user: @active_user,
      project: @active_project,
      original_month: Date.new(2026, 1, 1),
      applied_month: Date.new(2026, 2, 1),
      adjustment_amount: -18_000,
      memo: "修正前メモ"
    )
    deleting = BillingAdjustment.create!(
      user: @active_user,
      project: @active_project,
      original_month: Date.new(2026, 2, 1),
      applied_month: Date.new(2026, 3, 1),
      adjustment_amount: 4_000,
      memo: "削除対象"
    )

    assert_no_difference("BillingAdjustment.count") do
      post "/billing_adjustments/bulk_sync", params: {
        entries: [
          {
            id: updating.id,
            user_id: @active_user.id,
            project_id: @active_project.id,
            original_month: "2026-01",
            applied_month: "2026-02",
            adjustment_amount: -22_000,
            memo: "更新後メモ"
          },
          {
            user_id: @another_active_user.id,
            project_id: @another_active_project.id,
            original_month: "2026-04",
            applied_month: "2026-05",
            adjustment_amount: 10_000,
            memo: "新規作成"
          }
        ],
        deleted_ids: [ deleting.id ]
      }
    end

    assert_redirected_to master_path
    assert_equal -22_000, updating.reload.adjustment_amount.to_i
    assert_equal "更新後メモ", updating.memo
    assert_nil BillingAdjustment.find_by(id: deleting.id)
    created = BillingAdjustment.find_by(user_id: @another_active_user.id, project_id: @another_active_project.id, applied_month: Date.new(2026, 5, 1))
    assert_not_nil created
  end

  test "bulk sync rejects empty payload" do
    assert_no_difference("BillingAdjustment.count") do
      post "/billing_adjustments/bulk_sync", params: { entries: [], deleted_ids: [] }
    end

    assert_redirected_to master_path
  end

  test "bulk sync rejects invalid month" do
    assert_no_difference("BillingAdjustment.count") do
      post "/billing_adjustments/bulk_sync", params: {
        entries: [
          {
            user_id: @active_user.id,
            project_id: @active_project.id,
            original_month: "2026-13",
            applied_month: "2026-02",
            adjustment_amount: 1000,
            memo: "不正月"
          }
        ],
        deleted_ids: []
      }
    end

    assert_redirected_to master_path
  end

  test "bulk sync rejects invalid amount" do
    assert_no_difference("BillingAdjustment.count") do
      post "/billing_adjustments/bulk_sync", params: {
        entries: [
          {
            user_id: @active_user.id,
            project_id: @active_project.id,
            original_month: "2026-01",
            applied_month: "2026-02",
            adjustment_amount: "abc",
            memo: "不正金額"
          }
        ]
      }
    end

    assert_redirected_to master_path
  end

  test "bulk sync rejects malformed entry payload" do
    assert_no_difference("BillingAdjustment.count") do
      post "/billing_adjustments/bulk_sync", params: {
        entries: [ "invalid" ],
        deleted_ids: []
      }
    end

    assert_redirected_to master_path
  end

  test "bulk sync rejects blank memo" do
    assert_no_difference("BillingAdjustment.count") do
      post "/billing_adjustments/bulk_sync", params: {
        entries: [
          {
            user_id: @active_user.id,
            project_id: @active_project.id,
            original_month: "2026-01",
            applied_month: "2026-02",
            adjustment_amount: 1000,
            memo: "   "
          }
        ]
      }
    end

    assert_redirected_to master_path
  end

  test "bulk sync rejects deleted id that does not exist" do
    assert_no_difference("BillingAdjustment.count") do
      post "/billing_adjustments/bulk_sync", params: {
        entries: [],
        deleted_ids: [ 999_999 ]
      }
    end

    assert_redirected_to master_path
  end

  test "bulk sync rejects update id that does not exist" do
    assert_no_difference("BillingAdjustment.count") do
      post "/billing_adjustments/bulk_sync", params: {
        entries: [
          {
            id: 999_999,
            user_id: @active_user.id,
            project_id: @active_project.id,
            original_month: "2026-01",
            applied_month: "2026-02",
            adjustment_amount: 1000,
            memo: "不存在更新"
          }
        ],
        deleted_ids: []
      }
    end

    assert_redirected_to master_path
  end

  test "bulk sync rejects conflict between entry id and deleted ids" do
    existing = BillingAdjustment.create!(
      user: @active_user,
      project: @active_project,
      original_month: Date.new(2026, 1, 1),
      applied_month: Date.new(2026, 2, 1),
      adjustment_amount: -18_000,
      memo: "衝突確認"
    )

    post "/billing_adjustments/bulk_sync", params: {
      entries: [
        {
          id: existing.id,
          user_id: @active_user.id,
          project_id: @active_project.id,
          original_month: "2026-01",
          applied_month: "2026-02",
          adjustment_amount: -20_000,
          memo: "更新"
        }
      ],
      deleted_ids: [ existing.id ]
    }

    assert_redirected_to master_path
    assert_equal -18_000, existing.reload.adjustment_amount.to_i
  end

  test "bulk sync rejects inactive user on create" do
    assert_no_difference("BillingAdjustment.count") do
      post "/billing_adjustments/bulk_sync", params: {
        entries: [
          {
            user_id: @inactive_user.id,
            project_id: @active_project.id,
            original_month: "2026-01",
            applied_month: "2026-02",
            adjustment_amount: 1000,
            memo: "無効メンバー"
          }
        ]
      }
    end

    assert_redirected_to master_path
  end

  test "bulk sync rejects closed project on create" do
    assert_no_difference("BillingAdjustment.count") do
      post "/billing_adjustments/bulk_sync", params: {
        entries: [
          {
            user_id: @active_user.id,
            project_id: @closed_project.id,
            original_month: "2026-01",
            applied_month: "2026-02",
            adjustment_amount: 1000,
            memo: "終了案件"
          }
        ]
      }
    end

    assert_redirected_to master_path
  end

  test "bulk sync allows update when keeping existing inactive user and closed project" do
    existing = BillingAdjustment.create!(
      user: @inactive_user,
      project: @closed_project,
      original_month: Date.new(2026, 1, 1),
      applied_month: Date.new(2026, 2, 1),
      adjustment_amount: -10_000,
      memo: "既存データ"
    )

    post "/billing_adjustments/bulk_sync", params: {
      entries: [
        {
          id: existing.id,
          user_id: @inactive_user.id,
          project_id: @closed_project.id,
          original_month: "2026-01",
          applied_month: "2026-03",
          adjustment_amount: -12_000,
          memo: "既存参照維持更新"
        }
      ],
      deleted_ids: []
    }

    assert_redirected_to master_path
    assert_equal -12_000, existing.reload.adjustment_amount.to_i
    assert_equal Date.new(2026, 3, 1), existing.applied_month
  end

  test "bulk sync allows negative adjustment amount" do
    assert_difference("BillingAdjustment.count", 1) do
      post "/billing_adjustments/bulk_sync", params: {
        entries: [
          {
            user_id: @active_user.id,
            project_id: @active_project.id,
            original_month: "2026-01",
            applied_month: "2026-02",
            adjustment_amount: -1,
            memo: "マイナス許可"
          }
        ],
        deleted_ids: []
      }
    end

    assert_redirected_to master_path
  end

  test "bulk sync is atomic when payload contains invalid row" do
    assert_no_difference("BillingAdjustment.count") do
      post "/billing_adjustments/bulk_sync", params: {
        entries: [
          {
            user_id: @active_user.id,
            project_id: @active_project.id,
            original_month: "2026-01",
            applied_month: "2026-02",
            adjustment_amount: -1200,
            memo: "正常行"
          },
          {
            user_id: @active_user.id,
            project_id: @active_project.id,
            original_month: "2026-01",
            applied_month: "2026-99",
            adjustment_amount: -3000,
            memo: "異常行"
          }
        ],
        deleted_ids: []
      }
    end

    assert_redirected_to master_path
  end

  private

  def create_user(email, is_active:)
    User.create!(
      name: email.split("@").first,
      email: email,
      password: "password123",
      password_confirmation: "password123",
      system_role: "member",
      is_active: is_active,
      role: @role
    )
  end
end
