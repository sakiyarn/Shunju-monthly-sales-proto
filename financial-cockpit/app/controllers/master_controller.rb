# frozen_string_literal: true

class MasterController < InertiaController
  def index
    render inertia: "Master/Index", props: {
      users: users_payload,
      roles: roles_payload,
      projects: projects_payload,
      project_members: project_members_payload,
      s5_month_keys: s5_month_keys_payload,
      billing_work_logs: billing_work_logs_payload,
      staff_monthly_results: staff_monthly_results_payload,
      officer_monthly_results: officer_monthly_results_payload,
      monthly_business_days: monthly_business_days_payload,
      directed_expenses: directed_expenses_payload,
      monthly_accounting_data: monthly_accounting_data_payload,
      monthly_accounting_histories: monthly_accounting_histories_payload
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

  def project_members_payload
    ProjectMember
      .includes(:project, user: :role)
      .map do |project_member|
        payload = project_member.as_json(only: %i[id project_id user_id default_billing_rate])
        payload["default_billing_rate"] = project_member.default_billing_rate.to_i
        payload
      end
  end

  def s5_month_keys_payload
    BillingWorkLog
      .distinct
      .order(:work_month)
      .pluck(:work_month)
      .map { |month| month.strftime("%Y-%m") }
  end

  def billing_work_logs_payload
    BillingWorkLog
      .order(:project_id, :user_id, :work_month)
      .map do |log|
        {
          project_id: log.project_id,
          user_id: log.user_id,
          work_month: log.work_month.strftime("%Y-%m"),
          billed_hours: log.billed_hours.to_i,
          billing_rate: log.billing_rate.to_i
        }
      end
  end

  def monthly_accounting_data_payload
    MonthlyAccountingDatum
      .order(:work_month)
      .map do |row|
        {
          work_month: row.work_month.strftime("%Y-%m"),
          sales: decimal_to_number(row.sales),
          gross_profit: decimal_to_number(row.gross_profit),
          selling_general_admin_cost: decimal_to_number(row.selling_general_admin_cost),
          accounting_operating_profit: decimal_to_number(row.accounting_operating_profit)
        }
      end
  end

  def monthly_business_days_payload
    MonthlyBusinessDay
      .order(:work_month)
      .map do |row|
        {
          work_month: row.work_month.strftime("%Y-%m"),
          business_days: row.business_days
        }
      end
  end

  def directed_expenses_payload
    DirectedExpense
      .includes(:directed_expense_assignments)
      .order(work_month: :desc, id: :desc)
      .map do |expense|
        {
          id: expense.id,
          work_month: expense.work_month.strftime("%Y-%m"),
          description: expense.description.to_s,
          amount: expense.amount.to_i,
          project_ids: expense.directed_expense_assignments.map(&:project_id).uniq.sort
        }
      end
  end

  def staff_monthly_results_payload
    StaffMonthlyResult
      .joins(:user)
      .where(users: { is_active: true, system_role: "member" })
      .order(:user_id, :work_month)
      .map do |row|
        {
          user_id: row.user_id,
          work_month: row.work_month.strftime("%Y-%m"),
          salary: row.salary.to_i,
          legal_welfare: row.legal_welfare.to_i,
          welfare: row.welfare.to_i,
          bonus: row.bonus.to_i
        }
      end
  end

  def officer_monthly_results_payload
    StaffMonthlyResult
      .joins(user: :role)
      .where(users: { is_active: true }, roles: { name: "代表" })
      .order(:user_id, :work_month)
      .map do |row|
        {
          user_id: row.user_id,
          work_month: row.work_month.strftime("%Y-%m"),
          salary: row.salary.to_i,
          legal_welfare: row.legal_welfare.to_i,
          welfare: row.welfare.to_i,
          bonus: row.bonus.to_i
        }
      end
  end

  def monthly_accounting_histories_payload
    MonthlyAccountingDataHistory
      .recent_first
      .limit(MonthlyAccountingDataHistory::MAX_ENTRIES)
      .map do |history|
        {
          id: history.id,
          event_type: history.event_type,
          created_at: history.created_at.iso8601
        }
      end
  end

  def decimal_to_number(value)
    return nil if value.nil?
    return value.to_i if value.frac.zero?

    value.to_f
  end
end
