# frozen_string_literal: true

class MonthlyBusinessDay < ApplicationRecord
  validates :work_month, presence: true, uniqueness: true
  validates :business_days,
            numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 31 },
            allow_nil: true
end
