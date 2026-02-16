# frozen_string_literal: true

class AddIsActiveToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :is_active, :boolean, null: false, default: true
    add_index :users, :is_active
  end
end
