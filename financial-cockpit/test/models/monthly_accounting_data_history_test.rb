# frozen_string_literal: true

require "test_helper"

class MonthlyAccountingDataHistoryTest < ActiveSupport::TestCase
  test "keeps only the latest three history records" do
    row = MonthlyAccountingDatum.create!(
      work_month: Date.new(2025, 7, 1),
      sales: 1000,
      gross_profit: 400,
      selling_general_admin_cost: 100,
      accounting_operating_profit: 300
    )

    4.times do |index|
      row.update!(sales: 1000 + index)
      MonthlyAccountingDataHistory.capture!(event_type: "import")
    end

    assert_equal 3, MonthlyAccountingDataHistory.count
  end
end
