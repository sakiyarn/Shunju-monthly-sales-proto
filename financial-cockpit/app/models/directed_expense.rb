# frozen_string_literal: true

class DirectedExpense < ApplicationRecord
  has_many :directed_expense_assignments, dependent: :destroy
  has_many :projects, through: :directed_expense_assignments
end
