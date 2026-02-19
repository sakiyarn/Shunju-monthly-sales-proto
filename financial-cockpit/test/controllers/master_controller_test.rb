# frozen_string_literal: true

require "test_helper"

class MasterControllerTest < ActionDispatch::IntegrationTest
  test "master includes ordered projects props" do
    Project.create!(name: "Z Active", is_active: true)
    Project.create!(name: "A Active", is_active: true)
    Project.create!(name: "B Inactive", is_active: false)

    get master_path, headers: { "X-Inertia" => "true" }

    assert_response :success

    payload = JSON.parse(response.body)
    assert_equal "Master/Index", payload["component"]

    projects = payload.dig("props", "projects")
    assert projects.present?

    project_keys = projects.first.keys
    assert_includes project_keys, "id"
    assert_includes project_keys, "name"
    assert_includes project_keys, "is_active"
    assert_includes project_keys, "display_order"
    assert_includes project_keys, "related_records_count"
    assert_includes project_keys, "can_hard_delete"

    ordered_names = projects.map { |project| project["name"] }
    selected_names = ordered_names.select { |name| ["A Active", "Z Active", "B Inactive"].include?(name) }
    assert_equal ["A Active", "Z Active", "B Inactive"], selected_names
  end

  test "master includes project members props" do
    project = Project.create!(name: "案件A", is_active: true)
    user = User.create!(
      name: "テストメンバー",
      email: "master-project-member@example.com",
      password: "password123",
      password_confirmation: "password123",
      system_role: "member",
      is_active: true
    )
    project_member = ProjectMember.create!(project: project, user: user, default_billing_rate: 7_200)

    get master_path, headers: { "X-Inertia" => "true" }

    assert_response :success

    payload = JSON.parse(response.body)
    project_members = payload.dig("props", "project_members")
    assert project_members.present?

    response_member = project_members.find { |item| item["id"] == project_member.id }
    assert_not_nil response_member
    assert_equal project.id, response_member["project_id"]
    assert_equal user.id, response_member["user_id"]
    assert_equal 7_200, response_member["default_billing_rate"]
  end

  test "master includes monthly accounting data props" do
    accounting = MonthlyAccountingDatum.create!(
      work_month: Date.new(2025, 7, 1),
      sales: 5_814_500,
      gross_profit: 1_181_511,
      selling_general_admin_cost: 436_593,
      accounting_operating_profit: 744_918
    )

    get master_path, headers: { "X-Inertia" => "true" }

    assert_response :success

    payload = JSON.parse(response.body)
    accounting_rows = payload.dig("props", "monthly_accounting_data")
    assert accounting_rows.present?

    response_row = accounting_rows.find { |item| item["work_month"] == accounting.work_month.strftime("%Y-%m") }
    assert_not_nil response_row
    assert_equal 5_814_500, response_row["sales"]
    assert_equal 1_181_511, response_row["gross_profit"]
    assert_equal 436_593, response_row["selling_general_admin_cost"]
    assert_equal 744_918, response_row["accounting_operating_profit"]
  end

  test "master includes monthly accounting history props" do
    MonthlyAccountingDatum.create!(
      work_month: Date.new(2025, 7, 1),
      sales: 5_814_500,
      gross_profit: 1_181_511,
      selling_general_admin_cost: 436_593,
      accounting_operating_profit: 744_918
    )
    history = MonthlyAccountingDataHistory.capture!(event_type: "import")

    get master_path, headers: { "X-Inertia" => "true" }

    assert_response :success

    payload = JSON.parse(response.body)
    histories = payload.dig("props", "monthly_accounting_histories")
    assert histories.present?

    response_history = histories.find { |item| item["id"] == history.id }
    assert_not_nil response_history
    assert_equal "import", response_history["event_type"]
  end
end
