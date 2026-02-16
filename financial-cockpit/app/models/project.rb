# frozen_string_literal: true

class Project < ApplicationRecord
  has_many :project_members, dependent: :destroy
  has_many :users, through: :project_members
  has_many :billing_work_logs, dependent: :destroy
  has_many :directed_expense_assignments, dependent: :destroy
  has_many :directed_expenses, through: :directed_expense_assignments
  has_many :billing_adjustments, dependent: :destroy
end
