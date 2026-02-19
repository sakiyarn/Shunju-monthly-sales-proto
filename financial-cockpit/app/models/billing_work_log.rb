# frozen_string_literal: true

class BillingWorkLog < ApplicationRecord
  belongs_to :user
  belongs_to :project

  validates :work_month, presence: true
  validates :user_id, uniqueness: { scope: %i[project_id work_month] }
  validates :billed_hours, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 999 }
  validates :billing_rate, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 99_999 }
  validate :billing_rate_must_be_multiple_of_ten
  validate :user_must_be_assigned_to_project

  private

  def billing_rate_must_be_multiple_of_ten
    return if billing_rate.blank?
    return if billing_rate.to_i % 10 == 0

    errors.add(:billing_rate, "は10円単位で入力してください")
  end

  def user_must_be_assigned_to_project
    return if user_id.blank? || project_id.blank?
    return if ProjectMember.exists?(project_id: project_id, user_id: user_id)

    errors.add(:user_id, "は案件にアサインされていません")
  end
end
