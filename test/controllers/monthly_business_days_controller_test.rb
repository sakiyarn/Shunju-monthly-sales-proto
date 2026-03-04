# frozen_string_literal: true

require "test_helper"

class MonthlyBusinessDaysControllerTest < ActionDispatch::IntegrationTest
  test "bulk upsert creates and updates monthly business days" do
    existing = MonthlyBusinessDay.create!(work_month: Date.new(2026, 1, 1), business_days: 20)

    assert_difference("MonthlyBusinessDay.count", 1) do
      post "/monthly_business_days/bulk_upsert", params: {
        entries: [
          { work_month: "2026-01", business_days: 22 },
          { work_month: "2026-02", business_days: 19 }
        ]
      }
    end

    assert_redirected_to master_path
    assert_equal 22, existing.reload.business_days
    assert_equal 19, MonthlyBusinessDay.find_by!(work_month: Date.new(2026, 2, 1)).business_days
  end

  test "bulk upsert allows boundary values" do
    assert_difference("MonthlyBusinessDay.count", 2) do
      post "/monthly_business_days/bulk_upsert", params: {
        entries: [
          { work_month: "2026-03", business_days: 1 },
          { work_month: "2026-04", business_days: 31 }
        ]
      }
    end

    assert_redirected_to master_path
  end

  test "bulk upsert rejects empty entries" do
    assert_no_difference("MonthlyBusinessDay.count") do
      post "/monthly_business_days/bulk_upsert", params: {
        entries: []
      }
    end

    assert_redirected_to master_path
  end

  test "bulk upsert rejects blank entries payload" do
    assert_no_difference("MonthlyBusinessDay.count") do
      post "/monthly_business_days/bulk_upsert", params: {
        entries: ["", "   ", nil]
      }
    end

    assert_redirected_to master_path
  end

  test "bulk upsert rejects duplicated month in payload" do
    assert_no_difference("MonthlyBusinessDay.count") do
      post "/monthly_business_days/bulk_upsert", params: {
        entries: [
          { work_month: "2026-01", business_days: 20 },
          { work_month: "2026-01", business_days: 21 }
        ]
      }
    end

    assert_redirected_to master_path
  end

  test "bulk upsert rejects invalid month format" do
    assert_no_difference("MonthlyBusinessDay.count") do
      post "/monthly_business_days/bulk_upsert", params: {
        entries: [
          { work_month: "2026-13", business_days: 20 }
        ]
      }
    end

    assert_redirected_to master_path
  end

  test "bulk upsert rejects out of range business days" do
    assert_no_difference("MonthlyBusinessDay.count") do
      post "/monthly_business_days/bulk_upsert", params: {
        entries: [
          { work_month: "2026-05", business_days: 0 },
          { work_month: "2026-06", business_days: 32 }
        ]
      }
    end

    assert_redirected_to master_path
  end

  test "bulk upsert allows nil and skips new nil record" do
    existing = MonthlyBusinessDay.create!(work_month: Date.new(2026, 1, 1), business_days: 20)

    assert_no_difference("MonthlyBusinessDay.count") do
      post "/monthly_business_days/bulk_upsert", params: {
        entries: [
          { work_month: "2026-01", business_days: nil },
          { work_month: "2026-07", business_days: nil }
        ]
      }
    end

    assert_redirected_to master_path
    assert_nil existing.reload.business_days
    assert_nil MonthlyBusinessDay.find_by(work_month: Date.new(2026, 7, 1))
  end

  test "bulk upsert is atomic when payload includes invalid row" do
    assert_no_difference("MonthlyBusinessDay.count") do
      post "/monthly_business_days/bulk_upsert", params: {
        entries: [
          { work_month: "2026-08", business_days: 20 },
          { work_month: "2026-09", business_days: 0 }
        ]
      }
    end

    assert_redirected_to master_path
    assert_nil MonthlyBusinessDay.find_by(work_month: Date.new(2026, 8, 1))
  end
end
