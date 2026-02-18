# frozen_string_literal: true

class MasterController < InertiaController
  def index
    render inertia: "Master/Index", props: {
      users: users_payload,
      roles: roles_payload,
      projects: projects_payload
    }
  end

  private

  def users_payload
    project_member_counts = ProjectMember.group(:user_id).count
    billing_work_log_counts = BillingWorkLog.group(:user_id).count
    staff_monthly_result_counts = StaffMonthlyResult.group(:user_id).count
    billing_adjustment_counts = BillingAdjustment.group(:user_id).count

    User.ordered_for_master.map do |user|
      related_records_count = project_member_counts.fetch(user.id, 0) +
                              billing_work_log_counts.fetch(user.id, 0) +
                              staff_monthly_result_counts.fetch(user.id, 0) +
                              billing_adjustment_counts.fetch(user.id, 0)

      user.as_json(only: %i[id name email system_role role_id display_name is_active display_order]).merge(
        role_name: user.role&.name,
        related_records_count: related_records_count,
        can_hard_delete: related_records_count.zero?
      )
    end
  end

  def roles_payload
    Role.order(:display_order).as_json(only: %i[id name])
  end

  def projects_payload
    project_member_counts = ProjectMember.group(:project_id).count
    billing_work_log_counts = BillingWorkLog.group(:project_id).count
    directed_expense_assignment_counts = DirectedExpenseAssignment.group(:project_id).count
    billing_adjustment_counts = BillingAdjustment.group(:project_id).count

    Project.ordered_for_master.map do |project|
      related_records_count = project_member_counts.fetch(project.id, 0) +
                              billing_work_log_counts.fetch(project.id, 0) +
                              directed_expense_assignment_counts.fetch(project.id, 0) +
                              billing_adjustment_counts.fetch(project.id, 0)

      project.as_json(only: %i[id name is_active display_order]).merge(
        related_records_count: related_records_count,
        can_hard_delete: related_records_count.zero?
      )
    end
  end
end
