# frozen_string_literal: true

require "test_helper"

class MonthlyAccountingDataHistoriesControllerTest < ActionDispatch::IntegrationTest
  test "restores monthly accounting data from selected history" do
    row = MonthlyAccountingDatum.create!(
      work_month: Date.new(2025, 7, 1),
      sales: 1000,
      gross_profit: 400,
      selling_general_admin_cost: 100,
      accounting_operating_profit: 300
    )

    history = MonthlyAccountingDataHistory.capture!(event_type: "import")

    row.update!(
      sales: 7777,
      gross_profit: 8888,
      selling_general_admin_cost: 9999,
      accounting_operating_profit: 1111
    )

    post restore_monthly_accounting_data_history_path(history)

    assert_response :success

    body = JSON.parse(response.body)
    assert_equal "restored", body.fetch("status")

    restored = row.reload
    assert_equal 1000, restored.sales.to_i
    assert_equal 400, restored.gross_profit.to_i
    assert_equal 100, restored.selling_general_admin_cost.to_i
    assert_equal 300, restored.accounting_operating_profit.to_i
  end

  test "returns not found when selected history is missing" do
    post restore_monthly_accounting_data_history_path(id: 99_999)

    assert_response :not_found
    body = JSON.parse(response.body)
    assert_equal "error", body.fetch("status")
  end
end
