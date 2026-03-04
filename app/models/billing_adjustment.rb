# frozen_string_literal: true

class BillingAdjustment < ApplicationRecord
  belongs_to :user
  belongs_to :project

  validates :original_month, presence: true
  validates :applied_month, presence: true
  validates :memo, presence: true, length: { maximum: 255 }
  validates :adjustment_amount, presence: true, numericality: true
  validate :adjustment_amount_must_be_integer_yen

  private

  def adjustment_amount_must_be_integer_yen
    return if adjustment_amount.blank?
    return if adjustment_amount.to_d.frac.zero?

    errors.add(:adjustment_amount, "は円単位の整数で入力してください")
  end
end
