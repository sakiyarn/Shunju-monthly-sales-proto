# frozen_string_literal: true

class DirectedExpensesController < ApplicationController
  def create
    normalized = normalize_payload!(allow_empty_projects: false)
    incoming_active_project_ids = validate_active_project_ids!(normalized[:project_ids], allow_empty: false)

    expense = DirectedExpense.new(
      work_month: normalized[:work_month],
      description: normalized[:description],
      amount: normalized[:amount]
    )

    DirectedExpense.transaction do
      expense.save!
      incoming_active_project_ids.each do |project_id|
        expense.directed_expense_assignments.create!(project_id: project_id)
      end
    end

    redirect_to master_path, notice: "S9を保存しました"
  rescue ActiveRecord::RecordInvalid => e
    redirect_with_record_errors(e.record)
  rescue ActiveRecord::RecordNotUnique
    redirect_with_errors(project_ids: "対象案件が重複しています")
  rescue ArgumentError => e
    redirect_with_errors(directed_expense: e.message)
  end

  def update
    expense = DirectedExpense.find(params[:id])
    normalized = normalize_payload!(allow_empty_projects: true)
    incoming_active_project_ids = validate_active_project_ids!(normalized[:project_ids], allow_empty: true)

    existing_closed_project_ids = expense.directed_expense_assignments
                                       .joins(:project)
                                       .where(projects: { is_active: false })
                                       .pluck(:project_id)

    final_project_ids = (existing_closed_project_ids + incoming_active_project_ids).uniq
    return redirect_with_errors(project_ids: "案件を1件以上選択してください") if final_project_ids.empty?

    DirectedExpense.transaction do
      expense.assign_attributes(
        work_month: normalized[:work_month],
        description: normalized[:description],
        amount: normalized[:amount]
      )
      expense.save!

      # Keep existing closed project assignments as-is and replace only active project assignments.
      expense.directed_expense_assignments
            .joins(:project)
            .where(projects: { is_active: true })
            .delete_all

      incoming_active_project_ids.each do |project_id|
        expense.directed_expense_assignments.create!(project_id: project_id)
      end
    end

    redirect_to master_path, notice: "S9を保存しました"
  rescue ActiveRecord::RecordInvalid => e
    redirect_with_record_errors(e.record)
  rescue ActiveRecord::RecordNotUnique
    redirect_with_errors(project_ids: "対象案件が重複しています")
  rescue ArgumentError => e
    redirect_with_errors(directed_expense: e.message)
  end

  def destroy
    expense = DirectedExpense.find(params[:id])
    expense.destroy!

    redirect_to master_path, notice: "S9の経費を削除しました"
  end

  private

  def normalize_payload!(allow_empty_projects:)
    params_payload = params.require(:directed_expense).permit(:work_month, :description, :amount, project_ids: [])

    {
      work_month: parse_month(params_payload[:work_month]),
      description: parse_description(params_payload[:description]),
      amount: parse_amount(params_payload[:amount]),
      project_ids: parse_project_ids(params_payload[:project_ids], allow_empty: allow_empty_projects)
    }
  rescue ActionController::ParameterMissing
    raise ArgumentError, "保存データの形式が不正です"
  end

  def parse_month(value)
    month = value.to_s.strip
    raise ArgumentError, "対象月の形式が不正です" unless month.match?(/\A\d{4}-\d{2}\z/)

    Date.strptime(month, "%Y-%m")
  rescue Date::Error
    raise ArgumentError, "対象月の形式が不正です"
  end

  def parse_description(value)
    description = value.to_s.strip
    raise ArgumentError, "経費名は必須です" if description.blank?

    description
  end

  def parse_amount(value)
    number = Integer(value)
    raise ArgumentError, "金額は0以上の整数で入力してください" if number.negative?

    number
  rescue ArgumentError, TypeError
    raise ArgumentError, "金額は0以上の整数で入力してください"
  end

  def parse_project_ids(value, allow_empty:)
    raise ArgumentError, "対象案件の形式が不正です" unless value.is_a?(Array)

    project_ids = value.map do |project_id|
      Integer(project_id)
    rescue ArgumentError, TypeError
      raise ArgumentError, "対象案件の形式が不正です"
    end

    raise ArgumentError, "対象案件が重複しています" if project_ids.uniq.length != project_ids.length
    raise ArgumentError, "案件を1件以上選択してください" if project_ids.empty? && !allow_empty

    project_ids
  end

  def validate_active_project_ids!(project_ids, allow_empty:)
    return [] if project_ids.empty? && allow_empty
    raise ArgumentError, "案件を1件以上選択してください" if project_ids.empty?

    projects = Project.where(id: project_ids).to_a
    found_ids = projects.map(&:id)
    missing_ids = project_ids - found_ids
    raise ArgumentError, "存在しない案件が含まれています（project_id: #{missing_ids.first}）" if missing_ids.any?

    closed_project = projects.find { |project| !project.is_active }
    if closed_project
      raise ArgumentError, "終了案件は選択できません（project_id: #{closed_project.id}）"
    end

    project_ids
  end

  def redirect_with_record_errors(record)
    if record.is_a?(DirectedExpense)
      return redirect_with_errors(
        work_month: record.errors.full_messages_for(:work_month).first,
        description: record.errors.full_messages_for(:description).first,
        amount: record.errors.full_messages_for(:amount).first
      )
    end

    redirect_with_errors(directed_expense: record.errors.full_messages.first)
  end

  def redirect_with_errors(error_hash)
    redirect_back(
      fallback_location: master_path,
      inertia: { errors: error_hash.compact }
    )
  end
end
