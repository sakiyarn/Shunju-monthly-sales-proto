# frozen_string_literal: true

class Project < ApplicationRecord
  has_many :project_members, dependent: :restrict_with_exception
  has_many :users, through: :project_members
  has_many :billing_work_logs, dependent: :restrict_with_exception
  has_many :directed_expense_assignments, dependent: :restrict_with_exception
  has_many :directed_expenses, through: :directed_expense_assignments
  has_many :billing_adjustments, dependent: :restrict_with_exception

  scope :ordered_for_master, -> { order(is_active: :desc, display_order: :asc, name: :asc) }

  before_validation :normalize_name

  validates :name, presence: true
  validates :display_order, numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 9999 }

  private

  def normalize_name
    self.name = name.to_s.strip
  end
end
