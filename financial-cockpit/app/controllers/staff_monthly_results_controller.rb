# frozen_string_literal: true

class StaffMonthlyResultsController < ApplicationController
  def bulk_upsert
    entries = params[:entries]
    return redirect_with_errors(entries: "保存対象データがありません") unless entries.is_a?(Array) && entries.present?

    normalized_entries = normalize_entries(entries)
    return redirect_with_errors(entries: "同じメンバー・月のデータが重複しています") if duplicate_entries?(normalized_entries)

    editable_user_ids = User.where(is_active: true, system_role: "member").pluck(:id).to_set
    invalid_user_id = normalized_entries.find { |entry| !editable_user_ids.include?(entry[:user_id]) }&.dig(:user_id)
    if invalid_user_id
      return redirect_with_errors(user_id: "対象外のメンバーが含まれています（user_id: #{invalid_user_id}）")
    end

    records = normalized_entries.map do |entry|
      record = StaffMonthlyResult.find_or_initialize_by(user_id: entry[:user_id], work_month: entry[:work_month])
      record.assign_attributes(
        salary: entry[:salary],
        legal_welfare: entry[:legal_welfare],
        welfare: entry[:welfare],
        bonus: entry[:bonus]
      )
      record
    end

    invalid_record = records.find { |record| !record.valid? }
    if invalid_record
      return redirect_with_errors(
        user_id: invalid_record.errors.full_messages_for(:user_id).first,
        work_month: invalid_record.errors.full_messages_for(:work_month).first,
        salary: invalid_record.errors.full_messages_for(:salary).first,
        legal_welfare: invalid_record.errors.full_messages_for(:legal_welfare).first,
        welfare: invalid_record.errors.full_messages_for(:welfare).first,
        bonus: invalid_record.errors.full_messages_for(:bonus).first
      )
    end

    StaffMonthlyResult.transaction do
      records.each(&:save!)
    end

    redirect_to master_path, notice: "S7を保存しました"
  rescue ArgumentError => e
    redirect_with_errors(entries: e.message)
  end

  private

  def normalize_entries(entries)
    entries.map do |entry|
      {
        user_id: parse_user_id(entry[:user_id] || entry["user_id"]),
        work_month: parse_month(entry[:work_month] || entry["work_month"]),
        salary: parse_amount(entry[:salary] || entry["salary"], "給与"),
        legal_welfare: parse_amount(entry[:legal_welfare] || entry["legal_welfare"], "法定福利費"),
        welfare: parse_amount(entry[:welfare] || entry["welfare"], "福利厚生費"),
        bonus: parse_amount(entry[:bonus] || entry["bonus"], "賞与")
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

  def parse_amount(value, field_label)
    normalized = value.is_a?(String) ? value.strip : value
    normalized = 0 if normalized.nil? || normalized == ""

    number = Integer(normalized)
    raise ArgumentError, "#{field_label}は0以上の整数で入力してください" if number.negative?

    number
  rescue ArgumentError, TypeError
    raise ArgumentError, "#{field_label}は0以上の整数で入力してください"
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
