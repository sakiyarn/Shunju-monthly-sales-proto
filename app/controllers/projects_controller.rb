# frozen_string_literal: true

class ProjectsController < ApplicationController
  def create
    project = Project.new(project_params)
    project.display_order = suggested_display_order unless params.dig(:project, :display_order).present?

    if project.save
      redirect_to master_path, notice: "案件を追加しました"
    else
      redirect_back_with_inertia_errors(project)
    end
  end

  def update
    project = Project.find(params[:id])

    if project.update(project_params)
      redirect_to master_path, notice: "更新しました"
    else
      redirect_back_with_inertia_errors(project)
    end
  end

  def destroy
    project = Project.find(params[:id])

    if !project.is_active
      redirect_to master_path, alert: "この案件は既に終了しています"
    elsif project.update(is_active: false)
      redirect_to master_path, notice: "案件を終了しました"
    else
      redirect_to master_path, alert: "案件を終了できませんでした"
    end
  end

  def activate
    project = Project.find(params[:id])

    if project.is_active
      redirect_to master_path, alert: "この案件は既に進行中です"
    elsif project.update(is_active: true)
      redirect_to master_path, notice: "案件を再開しました"
    else
      redirect_to master_path, alert: "案件を再開できませんでした"
    end
  end

  def hard_destroy
    project = Project.find(params[:id])

    related_records_count = related_records_count_for(project)
    if related_records_count.positive?
      redirect_to master_path, alert: "関連データが#{related_records_count}件あるため削除できません"
      return
    end

    if project.destroy
      redirect_to master_path, notice: "案件を削除しました"
    else
      redirect_to master_path, alert: "案件を削除できませんでした"
    end
  rescue ActiveRecord::DeleteRestrictionError
    redirect_to master_path, alert: "関連データがあるため削除できません"
  end

  private

  def project_params
    permitted = params.require(:project).permit(:name, :display_order)
    if permitted.key?(:display_order)
      permitted[:display_order] = nil if permitted[:display_order].blank?
    end
    permitted
  end

  def redirect_back_with_inertia_errors(project)
    redirect_back(
      fallback_location: master_path,
      inertia: { errors: project.errors.to_hash(true) }
    )
  end

  def related_records_count_for(project)
    project.project_members.count +
      project.billing_work_logs.count +
      project.directed_expense_assignments.count +
      project.billing_adjustments.count
  end

  def suggested_display_order
    max_display_order = Project.maximum(:display_order).to_i
    [max_display_order + 1, 9999].min
  end
end
