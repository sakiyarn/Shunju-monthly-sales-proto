# frozen_string_literal: true

class AddGrossProfitToMonthlyAccountingData < ActiveRecord::Migration[7.2]
  DECIMAL_OPTIONS = { precision: 15, scale: 2 }.freeze

  def change
    add_column :monthly_accounting_data, :gross_profit, :decimal, **DECIMAL_OPTIONS
  end
end
