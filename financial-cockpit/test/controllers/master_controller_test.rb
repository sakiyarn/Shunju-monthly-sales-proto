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
end
