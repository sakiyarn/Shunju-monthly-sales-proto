# frozen_string_literal: true

class DirectedExpense < ApplicationRecord
  has_many :directed_expense_assignments, dependent: :destroy
  has_many :projects, through: :directed_expense_assignments

  validates :work_month, presence: true
  validates :description, presence: true, length: { maximum: 255 }
  validates :amount, numericality: { greater_than_or_equal_to: 0 }
  validate :amount_must_be_integer_yen

  private

  def amount_must_be_integer_yen
    return if amount.blank?
    return if amount.to_d.frac.zero?

    errors.add(:amount, "は円単位の整数で入力してください")
  end
end
