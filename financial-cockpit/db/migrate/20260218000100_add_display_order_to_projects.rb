# frozen_string_literal: true

class AddDisplayOrderToProjects < ActiveRecord::Migration[7.2]
  def up
    add_column :projects, :display_order, :integer, null: false, default: 9999
    add_index :projects, :display_order

    Project.reset_column_information
    Project.order(:created_at, :id).each.with_index(1) do |project, index|
      project.update_columns(display_order: index)
    end
  end

  def down
    remove_index :projects, :display_order
    remove_column :projects, :display_order
  end
end
