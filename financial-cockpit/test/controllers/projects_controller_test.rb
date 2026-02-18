# frozen_string_literal: true

require "test_helper"

class ProjectsControllerTest < ActionDispatch::IntegrationTest
  test "create project with valid params" do
    Project.create!(name: "既存案件1", is_active: true, display_order: 1)
    Project.create!(name: "既存案件2", is_active: true, display_order: 2)

    assert_difference("Project.count", 1) do
      post projects_path, params: { project: { name: "  新規案件  " } }
    end

    created = Project.order(:id).last
    assert_redirected_to master_path
    assert_equal "新規案件", created.name
    assert_predicate created, :is_active?
    assert_equal 3, created.display_order
  end

  test "create project with invalid params" do
    assert_no_difference("Project.count") do
      post projects_path, params: { project: { name: "   " } }
    end

    assert_redirected_to master_path
  end

  test "update project with valid params" do
    project = Project.create!(name: "既存案件", is_active: true)

    patch project_path(project), params: { project: { name: "  更新案件  " } }

    assert_redirected_to master_path
    assert_equal "更新案件", project.reload.name
    assert_predicate project, :is_active?
  end

  test "update project display order" do
    project = Project.create!(name: "既存案件", is_active: true, display_order: 10)

    patch project_path(project), params: { project: { display_order: 3 } }

    assert_redirected_to master_path
    assert_equal 3, project.reload.display_order
  end

  test "update project with invalid params" do
    project = Project.create!(name: "既存案件", is_active: true)

    patch project_path(project), params: { project: { name: " " } }

    assert_redirected_to master_path
    assert_equal "既存案件", project.reload.name
  end

  test "destroy project deactivates active project" do
    project = Project.create!(name: "進行案件", is_active: true)

    delete project_path(project)

    assert_redirected_to master_path
    assert_not project.reload.is_active
  end

  test "destroy project keeps already inactive project as inactive" do
    project = Project.create!(name: "終了案件", is_active: false)

    delete project_path(project)

    assert_redirected_to master_path
    assert_not project.reload.is_active
  end

  test "activate project turns inactive project to active" do
    project = Project.create!(name: "終了案件", is_active: false)

    patch activate_project_path(project)

    assert_redirected_to master_path
    assert project.reload.is_active
  end

  test "activate project keeps already active project as active" do
    project = Project.create!(name: "進行案件", is_active: true)

    patch activate_project_path(project)

    assert_redirected_to master_path
    assert project.reload.is_active
  end

  test "hard destroy project deletes when no related records" do
    project = Project.create!(name: "誤登録案件", is_active: true)

    assert_difference("Project.count", -1) do
      delete hard_destroy_project_path(project)
    end

    assert_redirected_to master_path
  end

  test "hard destroy project does not delete when related records exist" do
    project = Project.create!(name: "関連あり案件", is_active: true)
    user = User.create!(
      name: "テストユーザー",
      email: "project-hard-destroy-user@example.com",
      password: "password123",
      password_confirmation: "password123",
      system_role: "member"
    )
    ProjectMember.create!(project: project, user: user, default_billing_rate: 7000)

    assert_no_difference("Project.count") do
      delete hard_destroy_project_path(project)
    end

    assert_redirected_to master_path
    assert Project.exists?(project.id)
  end
end
