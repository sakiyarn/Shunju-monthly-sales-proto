# frozen_string_literal: true

class User < ApplicationRecord
  belongs_to :role, optional: true

  has_many :project_members, dependent: :restrict_with_exception
  has_many :projects, through: :project_members
  has_many :billing_work_logs, dependent: :restrict_with_exception
  has_many :staff_monthly_results, dependent: :restrict_with_exception
  has_many :billing_adjustments, dependent: :restrict_with_exception

  scope :ordered_for_master, -> { includes(:role).order(:display_order, :name) }

  validates :name, presence: true
  validates :email, presence: true, uniqueness: true
  validates :system_role, inclusion: { in: %w[admin member] }
  validates :display_order, numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 9999 }

  has_secure_password
end
