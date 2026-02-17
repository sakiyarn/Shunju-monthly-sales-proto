# frozen_string_literal: true

class BillingAdjustment < ApplicationRecord
  belongs_to :user
  belongs_to :project
end
