# frozen_string_literal: true

class StaffMonthlyResult < ApplicationRecord
  belongs_to :user

  validates :work_month, presence: true
  validates :user_id, uniqueness: { scope: :work_month }
  validates :salary, :legal_welfare, :welfare, :bonus,
            numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  validate :salary_must_be_multiple_of_1000
  validate :legal_welfare_must_be_multiple_of_1000
  validate :welfare_must_be_multiple_of_10
  validate :bonus_must_be_multiple_of_1000

  private

  def salary_must_be_multiple_of_1000
    validate_amount_step(:salary, 1000)
  end

  def legal_welfare_must_be_multiple_of_1000
    validate_amount_step(:legal_welfare, 1000)
  end

  def welfare_must_be_multiple_of_10
    validate_amount_step(:welfare, 10)
  end

  def bonus_must_be_multiple_of_1000
    validate_amount_step(:bonus, 1000)
  end

  def validate_amount_step(attribute, step)
    value = self[attribute]
    return if value.blank?
    return if value.to_i % step == 0

    errors.add(attribute, "は#{step}円単位で入力してください")
  end
end
