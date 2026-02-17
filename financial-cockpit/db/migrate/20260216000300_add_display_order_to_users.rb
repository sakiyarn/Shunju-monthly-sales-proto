# frozen_string_literal: true

class AddDisplayOrderToUsers < ActiveRecord::Migration[7.2]
  class MigrationUser < ApplicationRecord
    self.table_name = "users"
  end

  def up
    add_column :users, :display_order, :integer, null: false, default: 9999
    add_index :users, :display_order

    MigrationUser.reset_column_information
    MigrationUser.order(:id).each_with_index do |user, index|
      user.update_columns(display_order: index + 1)
    end
  end

  def down
    remove_index :users, :display_order
    remove_column :users, :display_order
  end
end
