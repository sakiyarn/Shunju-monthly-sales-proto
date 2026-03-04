# frozen_string_literal: true

class CreateMonthlyAccountingDataHistories < ActiveRecord::Migration[7.2]
  def change
    create_table :monthly_accounting_data_histories do |t|
      t.string :event_type, null: false
      t.json :snapshot_rows, null: false, default: []

      t.timestamps
    end

    add_index :monthly_accounting_data_histories, :created_at
  end
end
