# frozen_string_literal: true

class ProjectMember < ApplicationRecord
  belongs_to :project
  belongs_to :user

  validates :user_id, uniqueness: { scope: :project_id }
  validates :default_billing_rate, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
end
