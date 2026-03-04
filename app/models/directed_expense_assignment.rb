# frozen_string_literal: true

class DirectedExpenseAssignment < ApplicationRecord
  belongs_to :directed_expense
  belongs_to :project
end
