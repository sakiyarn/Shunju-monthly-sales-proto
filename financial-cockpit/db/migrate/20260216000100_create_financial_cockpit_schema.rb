# frozen_string_literal: true

class CreateFinancialCockpitSchema < ActiveRecord::Migration[7.2]
  DECIMAL_OPTIONS = { precision: 15, scale: 2 }.freeze

  def change
    create_table :roles do |t|
      t.string :name, null: false
      t.integer :display_order, null: false

      t.timestamps
    end
    add_index :roles, :name, unique: true

    create_table :users do |t|
      t.string :name, null: false
      t.string :email, null: false
      t.string :password_digest, null: false
      t.string :system_role, null: false, default: "member"
      t.references :role, foreign_key: true
      t.string :display_name

      t.timestamps
    end
    add_index :users, :email, unique: true

    create_table :projects do |t|
      t.string :name, null: false
      t.string :client_name
      t.boolean :is_active, null: false, default: true

      t.timestamps
    end

    create_table :project_members do |t|
      t.references :project, foreign_key: true
      t.references :user, foreign_key: true
      t.decimal :default_billing_rate, **DECIMAL_OPTIONS

      t.timestamps
    end
    add_index :project_members, %i[project_id user_id], unique: true

    create_table :monthly_accounting_data do |t|
      t.date :work_month, null: false
      t.decimal :sales, **DECIMAL_OPTIONS
      t.decimal :personnel_cost, **DECIMAL_OPTIONS
      t.decimal :selling_general_admin_cost, **DECIMAL_OPTIONS
      t.decimal :accounting_operating_profit, **DECIMAL_OPTIONS

      t.timestamps
    end
    add_index :monthly_accounting_data, :work_month, unique: true

    create_table :monthly_business_days do |t|
      t.date :work_month, null: false
      t.integer :business_days

      t.timestamps
    end
    add_index :monthly_business_days, :work_month, unique: true

    create_table :billing_work_logs do |t|
      t.references :user, foreign_key: true
      t.references :project, foreign_key: true
      t.date :work_month, null: false
      t.decimal :billed_hours, **DECIMAL_OPTIONS
      t.decimal :billing_rate, **DECIMAL_OPTIONS

      t.timestamps
    end
    add_index :billing_work_logs, %i[user_id project_id work_month], unique: true

    create_table :staff_monthly_results do |t|
      t.references :user, foreign_key: true
      t.date :work_month, null: false
      t.decimal :salary, **DECIMAL_OPTIONS
      t.decimal :legal_welfare, **DECIMAL_OPTIONS
      t.decimal :welfare, **DECIMAL_OPTIONS
      t.decimal :bonus, **DECIMAL_OPTIONS

      t.timestamps
    end
    add_index :staff_monthly_results, %i[user_id work_month], unique: true

    create_table :executive_adjustments do |t|
      t.date :work_month, null: false
      t.decimal :executive_salary, **DECIMAL_OPTIONS
      t.decimal :executive_welfare, **DECIMAL_OPTIONS
      t.decimal :executive_bonus, **DECIMAL_OPTIONS

      t.timestamps
    end
    add_index :executive_adjustments, :work_month

    create_table :directed_expenses do |t|
      t.date :work_month, null: false
      t.decimal :amount, **DECIMAL_OPTIONS
      t.string :description

      t.timestamps
    end

    create_table :directed_expense_assignments do |t|
      t.references :directed_expense, foreign_key: true
      t.references :project, foreign_key: true

      t.timestamps
    end
    add_index :directed_expense_assignments, %i[directed_expense_id project_id], unique: true, name: "idx_directed_expense_project"

    create_table :billing_adjustments do |t|
      t.references :user, foreign_key: true
      t.references :project, foreign_key: true
      t.date :original_month
      t.date :applied_month
      t.decimal :adjustment_amount, **DECIMAL_OPTIONS
      t.string :memo

      t.timestamps
    end
    add_index :billing_adjustments, %i[user_id project_id original_month applied_month], name: "idx_billing_adjustments_lookup"
  end
end
