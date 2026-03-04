# frozen_string_literal: true

class ProjectMembersController < ApplicationController
  before_action :set_project_member, only: %i[update destroy]

  def create
    project_member = ProjectMember.new(project_member_params)

    guard_message = guard_message_for_create(project_member)
    if guard_message
      redirect_to master_path, alert: guard_message
    elsif project_member.save
      redirect_to master_path, notice: "アサインを追加しました"
    else
      redirect_back_with_inertia_errors(project_member)
    end
  end

  def update
    if !project_member.project.is_active
      redirect_to master_path, alert: "終了案件のアサインは編集できません"
    elsif project_member.update(project_member_rate_params)
      redirect_to master_path, notice: "デフォルト売上単価を更新しました"
    else
      redirect_back_with_inertia_errors(project_member)
    end
  end

  def destroy
    if !project_member.project.is_active
      redirect_to master_path, alert: "終了案件のアサインは解除できません"
    elsif project_member.destroy
      redirect_to master_path, notice: "アサインを解除しました"
    else
      redirect_to master_path, alert: "アサインを解除できませんでした"
    end
  end

  private

  def set_project_member
    @project_member = ProjectMember.find(params[:id])
  end

  def project_member
    @project_member
  end

  def project_member_params
    permitted = params.require(:project_member).permit(:project_id, :user_id, :default_billing_rate)
    normalize_default_billing_rate(permitted)
  end

  def project_member_rate_params
    permitted = params.require(:project_member).permit(:default_billing_rate)
    normalize_default_billing_rate(permitted)
  end

  def normalize_default_billing_rate(permitted)
    return permitted unless permitted.key?(:default_billing_rate)

    permitted[:default_billing_rate] = nil if permitted[:default_billing_rate].blank?
    permitted
  end

  def guard_message_for_create(project_member)
    project = project_member.project
    return "対象案件が存在しません" if project.blank?
    return "終了案件にはアサインを追加できません" unless project.is_active

    user = project_member.user
    return "対象メンバーが存在しません" if user.blank?
    return "無効メンバーはアサインできません" unless user.is_active

    nil
  end

  def redirect_back_with_inertia_errors(project_member)
    redirect_back(
      fallback_location: master_path,
      inertia: { errors: project_member.errors.to_hash(true) }
    )
  end
end
