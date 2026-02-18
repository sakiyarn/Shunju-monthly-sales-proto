# frozen_string_literal: true

require "test_helper"

class ProjectMembersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @active_project = Project.create!(name: "進行案件", is_active: true)
    @closed_project = Project.create!(name: "終了案件", is_active: false)
    @active_user = create_user(name: "有効ユーザー", email: "active-member@example.com", is_active: true)
    @inactive_user = create_user(name: "無効ユーザー", email: "inactive-member@example.com", is_active: false)
  end

  test "create project member with valid params" do
    assert_difference("ProjectMember.count", 1) do
      post project_members_path, params: {
        project_member: {
          project_id: @active_project.id,
          user_id: @active_user.id,
          default_billing_rate: 8_000
        }
      }
    end

    created = ProjectMember.order(:id).last
    assert_redirected_to master_path
    assert_equal @active_project.id, created.project_id
    assert_equal @active_user.id, created.user_id
    assert_equal 8_000, created.default_billing_rate.to_i
  end

  test "create project member rejects duplicate assignment" do
    ProjectMember.create!(project: @active_project, user: @active_user, default_billing_rate: 7_000)

    assert_no_difference("ProjectMember.count") do
      post project_members_path, params: {
        project_member: {
          project_id: @active_project.id,
          user_id: @active_user.id,
          default_billing_rate: 7_500
        }
      }
    end

    assert_redirected_to master_path
  end

  test "create project member rejects closed project" do
    assert_no_difference("ProjectMember.count") do
      post project_members_path, params: {
        project_member: {
          project_id: @closed_project.id,
          user_id: @active_user.id,
          default_billing_rate: 7_000
        }
      }
    end

    assert_redirected_to master_path
    assert_equal "終了案件にはアサインを追加できません", flash[:alert]
  end

  test "create project member rejects inactive user" do
    assert_no_difference("ProjectMember.count") do
      post project_members_path, params: {
        project_member: {
          project_id: @active_project.id,
          user_id: @inactive_user.id,
          default_billing_rate: 7_000
        }
      }
    end

    assert_redirected_to master_path
    assert_equal "無効メンバーはアサインできません", flash[:alert]
  end

  test "update project member rate allows zero" do
    project_member = ProjectMember.create!(project: @active_project, user: @active_user, default_billing_rate: 7_000)

    patch project_member_path(project_member), params: { project_member: { default_billing_rate: 0 } }

    assert_redirected_to master_path
    assert_equal 0, project_member.reload.default_billing_rate.to_i
  end

  test "update project member rate rejects negative value" do
    project_member = ProjectMember.create!(project: @active_project, user: @active_user, default_billing_rate: 7_000)

    patch project_member_path(project_member), params: { project_member: { default_billing_rate: -1 } }

    assert_redirected_to master_path
    assert_equal 7_000, project_member.reload.default_billing_rate.to_i
  end

  test "update project member rejects closed project" do
    project_member = ProjectMember.create!(project: @closed_project, user: @active_user, default_billing_rate: 7_000)

    patch project_member_path(project_member), params: { project_member: { default_billing_rate: 8_000 } }

    assert_redirected_to master_path
    assert_equal "終了案件のアサインは編集できません", flash[:alert]
    assert_equal 7_000, project_member.reload.default_billing_rate.to_i
  end

  test "destroy project member on active project" do
    project_member = ProjectMember.create!(project: @active_project, user: @active_user, default_billing_rate: 7_000)

    assert_difference("ProjectMember.count", -1) do
      delete project_member_path(project_member)
    end

    assert_redirected_to master_path
  end

  test "destroy project member rejects closed project" do
    project_member = ProjectMember.create!(project: @closed_project, user: @active_user, default_billing_rate: 7_000)

    assert_no_difference("ProjectMember.count") do
      delete project_member_path(project_member)
    end

    assert_redirected_to master_path
    assert_equal "終了案件のアサインは解除できません", flash[:alert]
  end

  private

  def create_user(name:, email:, is_active:)
    User.create!(
      name: name,
      email: email,
      password: "password123",
      password_confirmation: "password123",
      system_role: "member",
      is_active: is_active
    )
  end
end
