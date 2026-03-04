# frozen_string_literal: true

class BillingWorkLogsController < ApplicationController
  def bulk_upsert
    project = Project.find_by(id: params[:project_id])
    return redirect_with_errors(project: "対象案件が存在しません") if project.blank?
    return redirect_with_errors(project: "終了案件の稼働実績は編集できません") unless project.is_active

    entries = normalize_entries_param(params[:entries])
    return redirect_with_errors(entries: "保存対象データがありません") if entries.empty?

    normalized_entries = normalize_entries(entries)
    return redirect_with_errors(entries: "同じメンバー・月のデータが重複しています") if duplicate_entries?(normalized_entries)

    assigned_user_ids = ProjectMember.where(project_id: project.id).pluck(:user_id).to_set
    invalid_assignee = normalized_entries.find { |entry| !assigned_user_ids.include?(entry[:user_id]) }
    if invalid_assignee
      return redirect_with_errors(entries: "アサインされていないメンバーが含まれています（user_id: #{invalid_assignee[:user_id]}）")
    end

    logs = normalized_entries.map do |entry|
      log = BillingWorkLog.find_or_initialize_by(
        project_id: project.id,
        user_id: entry[:user_id],
        work_month: entry[:work_month]
      )
      log.assign_attributes(
        billed_hours: entry[:billed_hours],
        billing_rate: entry[:billing_rate]
      )
      log
    end

    invalid_log = logs.find { |log| !log.valid? }
    if invalid_log
      return redirect_with_errors(
        billed_hours: invalid_log.errors.full_messages_for(:billed_hours).first,
        billing_rate: invalid_log.errors.full_messages_for(:billing_rate).first,
        user_id: invalid_log.errors.full_messages_for(:user_id).first,
        work_month: invalid_log.errors.full_messages_for(:work_month).first
      )
    end

    BillingWorkLog.transaction do
      logs.each(&:save!)
    end

    redirect_to master_path, notice: "S5を保存しました"
  rescue ArgumentError => e
    redirect_with_errors(entries: e.message)
  end

  private

  def normalize_entries_param(entries)
    return [] if entries.nil?
    raise ArgumentError, "保存データの形式が不正です" unless entries.is_a?(Array)

    entries.each_with_object([]) do |entry, normalized_entries|
      next if entry.nil?

      if entry.is_a?(String)
        next if entry.strip == ""

        raise ArgumentError, "保存データの形式が不正です"
      end

      unless entry.is_a?(Hash) || entry.is_a?(ActionController::Parameters)
        raise ArgumentError, "保存データの形式が不正です"
      end

      normalized_entries << entry
    end
  end

  def normalize_entries(entries)
    entries.map do |entry|
      {
        user_id: parse_user_id(entry[:user_id] || entry["user_id"]),
        work_month: parse_month(entry[:work_month] || entry["work_month"]),
        billed_hours: normalize_number(entry[:billed_hours] || entry["billed_hours"]),
        billing_rate: normalize_number(entry[:billing_rate] || entry["billing_rate"])
      }
    end
  end

  def parse_user_id(value)
    Integer(value)
  rescue ArgumentError, TypeError
    raise ArgumentError, "対象メンバーが不正です"
  end

  def parse_month(value)
    month = value.to_s.strip
    raise ArgumentError, "対象月の形式が不正です" unless month.match?(/\A\d{4}-\d{2}\z/)

    Date.strptime(month, "%Y-%m")
  rescue Date::Error
    raise ArgumentError, "対象月の形式が不正です"
  end

  def normalize_number(value)
    number = value.presence || 0
    Integer(number)
  rescue ArgumentError, TypeError
    raise ArgumentError, "入力値は整数で指定してください"
  end

  def duplicate_entries?(entries)
    keys = entries.map { |entry| [entry[:user_id], entry[:work_month]] }
    keys.uniq.length != keys.length
  end

  def redirect_with_errors(error_hash)
    redirect_back(
      fallback_location: master_path,
      inertia: { errors: error_hash.compact }
    )
  end
end
