# frozen_string_literal: true

require "test_helper"
require "rack/test"

class MonthlyAccountingDataImportsControllerTest < ActionDispatch::IntegrationTest
  include ActiveSupport::Testing::TimeHelpers

  teardown do
    travel_back
  end

  test "imports valid csv and creates monthly accounting rows" do
    travel_to(Time.utc(2026, 2, 18, 0, 0, 0))

    assert_difference("MonthlyAccountingDatum.count", 3) do
      post monthly_accounting_data_import_path, params: { file: upload_fixture("valid_accounting.csv") }
    end

    assert_response :success
    body = response_json
    assert_equal "imported", body.fetch("status")

    july = MonthlyAccountingDatum.find_by(work_month: Date.new(2025, 7, 1))
    assert_not_nil july
    assert_equal 1_000, july.sales.to_i
    assert_equal 400, july.gross_profit.to_i
    assert_equal 100, july.selling_general_admin_cost.to_i
    assert_equal 300, july.accounting_operating_profit.to_i
  end

  test "returns confirmation_required when existing row has differences" do
    travel_to(Time.utc(2026, 2, 18, 0, 0, 0))

    existing = MonthlyAccountingDatum.create!(
      work_month: Date.new(2025, 7, 1),
      sales: 999,
      gross_profit: 111,
      selling_general_admin_cost: 55,
      accounting_operating_profit: 56
    )

    post monthly_accounting_data_import_path, params: { file: upload_fixture("valid_accounting.csv") }

    assert_response :success
    body = response_json
    assert_equal "confirmation_required", body.fetch("status")
    assert body.fetch("diffs").present?
    assert_equal 999, existing.reload.sales.to_i
  end

  test "updates changed rows when confirm flag is true" do
    travel_to(Time.utc(2026, 2, 18, 0, 0, 0))

    existing = MonthlyAccountingDatum.create!(
      work_month: Date.new(2025, 7, 1),
      sales: 999,
      gross_profit: 111,
      selling_general_admin_cost: 55,
      accounting_operating_profit: 56
    )

    post monthly_accounting_data_import_path, params: {
      file: upload_fixture("valid_accounting.csv"),
      confirm_overwrite_changed: "true"
    }

    assert_response :success
    body = response_json
    assert_equal "imported", body.fetch("status")
    assert_equal 1_000, existing.reload.sales.to_i
  end

  test "rejects csv when future month has non-zero value" do
    travel_to(Time.utc(2026, 2, 18, 0, 0, 0))

    assert_no_difference("MonthlyAccountingDatum.count") do
      post monthly_accounting_data_import_path, params: { file: upload_fixture("future_month_non_zero.csv") }
    end

    assert_response :unprocessable_entity
    body = response_json
    assert_equal "error", body.fetch("status")
    assert_match "未来月", body.fetch("message")
  end

  test "imports cp932 csv" do
    travel_to(Time.utc(2026, 2, 18, 0, 0, 0))

    post monthly_accounting_data_import_path, params: { file: upload_fixture("cp932_accounting.csv") }

    assert_response :success
    body = response_json
    assert_equal "imported", body.fetch("status")

    july = MonthlyAccountingDatum.find_by(work_month: Date.new(2025, 7, 1))
    assert_not_nil july
    assert_equal 1_000, july.sales.to_i
  end

  private

  def upload_fixture(filename)
    Rack::Test::UploadedFile.new(file_fixture(filename), "text/csv")
  end

  def response_json
    JSON.parse(response.body)
  end
end
