# frozen_string_literal: true

require "date"

def month_date(month_key)
  Date.strptime("#{month_key}-01", "%Y-%m-%d")
end

def seeded_int(seed, min, max)
  hash = 2_166_136_261
  seed.each_byte do |byte|
    hash ^= byte
    hash = (hash * 16_777_619) & 0xffff_ffff
  end

  signed_hash = hash >= 0x8000_0000 ? hash - 0x1_0000_0000 : hash
  range = max - min + 1
  normalized = signed_hash.abs % range
  min + normalized
end

ActiveRecord::Base.transaction do
  DirectedExpenseAssignment.delete_all
  DirectedExpense.delete_all
  BillingAdjustment.delete_all
  BillingWorkLog.delete_all
  ProjectMember.delete_all
  StaffMonthlyResult.delete_all
  ExecutiveAdjustment.delete_all
  MonthlyBusinessDay.delete_all
  MonthlyAccountingDatum.delete_all
  Project.delete_all
  User.delete_all
  Role.delete_all

  role_names = ["代表", "三千人将", "千人将", "三百人将", "百人将", "什長", "伍長", "兵卒", "研修生", "未設定"]
  roles_by_name = role_names.each_with_index.each_with_object({}) do |(name, index), roles|
    roles[name] = Role.create!(name:, display_order: index + 1)
  end

  users_seed = [
    { code: "u01", name: "田中 太郎", email: "tanaka@example.com", system_role: "admin", role_name: "代表", display_name: "代表A", display_order: 10 },
    { code: "u02", name: "佐藤 花子", email: "sato@example.com", system_role: "admin", role_name: "代表", display_name: "代表B", display_order: 20 },
    { code: "u03", name: "鈴木 一郎", email: "suzuki@example.com", system_role: "member", role_name: "三千人将", display_name: "三千人将A", display_order: 30 },
    { code: "u04", name: "高橋 春菜", email: "takahashi@example.com", system_role: "member", role_name: "千人将", display_name: "千人将A", display_order: 40 },
    { code: "u05", name: "伊藤 翔", email: "ito@example.com", system_role: "member", role_name: "三百人将", display_name: "三百人将A", display_order: 50 },
    { code: "u06", name: "渡辺 美咲", email: "watanabe@example.com", system_role: "member", role_name: "百人将", display_name: "百人将A", display_order: 60 },
    { code: "u07", name: "山本 隆", email: "yamamoto@example.com", system_role: "member", role_name: "什長", display_name: "什長A", display_order: 70 },
    { code: "u08", name: "中村 彩", email: "nakamura@example.com", system_role: "member", role_name: "什長", display_name: "什長B", display_order: 80 },
    { code: "u09", name: "小林 健", email: "kobayashi@example.com", system_role: "member", role_name: "什長", display_name: "什長C", display_order: 90 },
    { code: "u10", name: "加藤 綾", email: "kato@example.com", system_role: "member", role_name: "什長", display_name: "什長D", display_order: 100 }
  ]

  users_by_code = {}
  users_by_name = {}
  users_by_display_name = {}

  users_seed.each do |user_seed|
    user = User.new(
      name: user_seed[:name],
      email: user_seed[:email],
      system_role: user_seed[:system_role],
      role: roles_by_name.fetch(user_seed[:role_name]),
      display_name: user_seed[:display_name],
      display_order: user_seed[:display_order],
      is_active: true,
      password: "password123",
      password_confirmation: "password123"
    )
    user.save!

    users_by_code[user_seed[:code]] = user
    users_by_name[user_seed[:name]] = user
    users_by_display_name[user_seed[:display_name]] = user
  end

  projects_seed = [
    { code: "p001", name: "案件001", client_name: "Alpha株式会社", is_active: true },
    { code: "p002", name: "案件002", client_name: "Beta株式会社", is_active: true },
    { code: "p003", name: "案件003", client_name: "Gamma株式会社", is_active: false }
  ]

  projects_by_code = {}
  projects_by_name = {}

  projects_seed.each do |project_seed|
    project = Project.create!(
      name: project_seed[:name],
      client_name: project_seed[:client_name],
      is_active: project_seed[:is_active]
    )

    projects_by_code[project_seed[:code]] = project
    projects_by_name[project_seed[:name]] = project
  end

  default_rate_by_user_code = {
    "u01" => 12_000,
    "u02" => 11_500,
    "u03" => 7_000,
    "u04" => 6_800,
    "u05" => 6_500,
    "u06" => 6_400,
    "u07" => 6_200,
    "u08" => 6_600,
    "u09" => 6_300,
    "u10" => 6_100
  }

  project_member_seed = [
    { project_code: "p001", user_code: "u03" },
    { project_code: "p001", user_code: "u04" },
    { project_code: "p001", user_code: "u05" },
    { project_code: "p001", user_code: "u06" },
    { project_code: "p001", user_code: "u07" },
    { project_code: "p001", user_code: "u01" },
    { project_code: "p002", user_code: "u03" },
    { project_code: "p002", user_code: "u04" },
    { project_code: "p002", user_code: "u08" },
    { project_code: "p002", user_code: "u09" },
    { project_code: "p002", user_code: "u10" },
    { project_code: "p002", user_code: "u02" },
    { project_code: "p003", user_code: "u05" },
    { project_code: "p003", user_code: "u06" },
    { project_code: "p003", user_code: "u07" },
    { project_code: "p003", user_code: "u08" },
    { project_code: "p003", user_code: "u09" },
    { project_code: "p003", user_code: "u10" },
    { project_code: "p003", user_code: "u01" },
    { project_code: "p003", user_code: "u02" }
  ]

  project_member_seed.each do |seed|
    ProjectMember.create!(
      project: projects_by_code.fetch(seed[:project_code]),
      user: users_by_code.fetch(seed[:user_code]),
      default_billing_rate: default_rate_by_user_code.fetch(seed[:user_code])
    )
  end

  all_month_keys = []
  month_cursor = Date.new(2025, 1, 1)
  while month_cursor <= Date.new(2026, 7, 1)
    all_month_keys << month_cursor.strftime("%Y-%m")
    month_cursor = month_cursor.next_month
  end

  accounting_seed = {
    "2025-08" => { sales: 3_600_000, personnel_cost: 1_850_000, gross_profit: 1_750_000, selling_general_admin_cost: 180_000, accounting_operating_profit: 1_570_000 },
    "2025-09" => { sales: 3_800_000, personnel_cost: 1_920_000, gross_profit: 1_880_000, selling_general_admin_cost: 220_000, accounting_operating_profit: 1_660_000 },
    "2025-10" => { sales: 3_900_000, personnel_cost: 1_990_000, gross_profit: 1_910_000, selling_general_admin_cost: 210_000, accounting_operating_profit: 1_700_000 },
    "2025-11" => { sales: 4_100_000, personnel_cost: 2_060_000, gross_profit: 2_030_000, selling_general_admin_cost: 240_000, accounting_operating_profit: 1_790_000 },
    "2025-12" => { sales: 4_200_000, personnel_cost: 2_120_000, gross_profit: 2_080_000, selling_general_admin_cost: 260_000, accounting_operating_profit: 1_820_000 },
    "2026-01" => { sales: 3_950_000, personnel_cost: 2_010_000, gross_profit: 1_940_000, selling_general_admin_cost: 200_000, accounting_operating_profit: 1_740_000 }
  }

  business_days_seed = {
    "2025-08" => 22,
    "2025-09" => 20,
    "2025-10" => 22,
    "2025-11" => 20,
    "2025-12" => 20,
    "2026-01" => 18
  }

  all_month_keys.each do |month_key|
    work_month = month_date(month_key)
    accounting = accounting_seed[month_key]

    MonthlyAccountingDatum.create!(
      work_month:,
      sales: accounting&.fetch(:sales, nil),
      personnel_cost: accounting&.fetch(:personnel_cost, nil),
      gross_profit: accounting&.fetch(:gross_profit, nil),
      selling_general_admin_cost: accounting&.fetch(:selling_general_admin_cost, nil),
      accounting_operating_profit: accounting&.fetch(:accounting_operating_profit, nil)
    )

    MonthlyBusinessDay.create!(
      work_month:,
      business_days: business_days_seed[month_key]
    )
  end

  seven_month_keys = %w[2025-08 2025-09 2025-10 2025-11 2025-12 2026-01 2026-02]
  dashboard_project_names = ["案件001", "案件002", "案件003"]
  dashboard_people = ["三千人将A", "千人将A", "三百人将A", "百人将A", "什長A", "什長B", "什長C", "什長D", "代表A", "代表B"]

  dashboard_people.each do |display_name|
    user = users_by_display_name.fetch(display_name)

    dashboard_project_names.each do |project_name|
      project = projects_by_name.fetch(project_name)

      seven_month_keys.each do |month_key|
        BillingWorkLog.create!(
          user:,
          project:,
          work_month: month_date(month_key),
          billed_hours: seeded_int("#{display_name}:#{project_name}:#{month_key}:billed-hours", 12, 68),
          billing_rate: seeded_int("#{display_name}:#{project_name}:#{month_key}:billing-rate", 4_000, 7_600)
        )
      end
    end
  end

  member_cost_names = ["鈴木 一郎", "高橋 春菜", "伊藤 翔", "渡辺 美咲", "山本 隆", "中村 彩", "小林 健", "加藤 綾"]
  executive_display_names = ["代表A", "代表B"]

  seven_month_keys.each_with_index do |month_key, month_index|
    work_month = month_date(month_key)

    member_cost_names.each_with_index do |member_name, member_index|
      salary = 280_000 + (member_index * 12_000) + (month_index * 4_000)
      legal_welfare = (salary * 0.16).round
      welfare = 12_000 + (member_index * 1_000) + (month_index * 400)
      bonus = month_key.end_with?("-12", "-02") ? 70_000 + (member_index * 3_000) : 0

      StaffMonthlyResult.create!(
        user: users_by_name.fetch(member_name),
        work_month:,
        salary:,
        legal_welfare:,
        welfare:,
        bonus:
      )
    end

    executive_salary_total = 0
    executive_welfare_total = 0
    executive_bonus_total = 0

    executive_display_names.each_with_index do |display_name, executive_index|
      salary = 500_000 + (executive_index * 15_000) + (month_index * 4_000)
      legal_welfare = (salary * 0.16).round
      welfare = 12_000 + (executive_index * 1_000) + (month_index * 400)
      bonus = month_key.end_with?("-12", "-02") ? 70_000 + (executive_index * 5_000) : 0

      StaffMonthlyResult.create!(
        user: users_by_display_name.fetch(display_name),
        work_month:,
        salary:,
        legal_welfare:,
        welfare:,
        bonus:
      )

      executive_salary_total += salary
      executive_welfare_total += legal_welfare + welfare
      executive_bonus_total += bonus
    end

    ExecutiveAdjustment.create!(
      work_month:,
      executive_salary: executive_salary_total,
      executive_welfare: executive_welfare_total,
      executive_bonus: executive_bonus_total
    )
  end

  directed_expense_seed = [
    { month_key: "2025-11", description: "Kaigi on Rails 参加費", amount: 100_000, project_codes: %w[p001 p002] },
    { month_key: "2025-12", description: "Laravel ライセンス", amount: 50_000, project_codes: %w[p003] }
  ]

  directed_expense_seed.each do |expense_seed|
    directed_expense = DirectedExpense.create!(
      work_month: month_date(expense_seed[:month_key]),
      description: expense_seed[:description],
      amount: expense_seed[:amount]
    )

    expense_seed[:project_codes].each do |project_code|
      DirectedExpenseAssignment.create!(
        directed_expense:,
        project: projects_by_code.fetch(project_code)
      )
    end
  end

  BillingAdjustment.create!(
    user: users_by_code.fetch("u04"),
    project: projects_by_code.fetch("p002"),
    original_month: month_date("2026-01"),
    applied_month: month_date("2026-02"),
    adjustment_amount: -18_000,
    memo: "1月分 請求時間誤り修正"
  )
end
