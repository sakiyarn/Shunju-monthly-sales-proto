# frozen_string_literal: true

class BillingWorkLog < ApplicationRecord
  belongs_to :user
  belongs_to :project
end
