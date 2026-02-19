# frozen_string_literal: true

class MonthlyAccountingDatum < ApplicationRecord
  validates :work_month, presence: true, uniqueness: true
  validates :sales, :personnel_cost, :gross_profit, :selling_general_admin_cost, :accounting_operating_profit,
            numericality: true, allow_nil: true
end
