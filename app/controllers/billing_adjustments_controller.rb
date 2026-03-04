# frozen_string_literal: true

class BillingAdjustmentsController < ApplicationController
  def bulk_sync
    entries = normalize_entries(params[:entries])
    deleted_ids = normalize_deleted_ids(params[:deleted_ids])

    if entries.empty? && deleted_ids.empty?
      return redirect_with_errors(entries: "保存対象データがありません")
    end

    entry_ids = entries.filter_map { |entry| entry[:id] }
    return redirect_with_errors(entries: "更新対象IDが重複しています") if duplicate_values?(entry_ids)
    return redirect_with_errors(deleted_ids: "削除対象IDが重複しています") if duplicate_values?(deleted_ids)

    overlap_id = (entry_ids & deleted_ids).first
    if overlap_id
      return redirect_with_errors(entries: "更新対象と削除対象が重複しています（id: #{overlap_id}）")
    end

    existing_entries_by_id = BillingAdjustment.where(id: entry_ids).index_by(&:id)
    missing_entry_id = (entry_ids - existing_entries_by_id.keys).first
    return redirect_with_errors(entries: "更新対象が存在しません（id: #{missing_entry_id}）") if missing_entry_id

    existing_deleted_ids = BillingAdjustment.where(id: deleted_ids).pluck(:id)
    missing_deleted_id = (deleted_ids - existing_deleted_ids).first
    return redirect_with_errors(deleted_ids: "削除対象が存在しません（id: #{missing_deleted_id}）") if missing_deleted_id

    validate_user_and_project_existence!(entries)
    validate_reference_editability!(entries, existing_entries_by_id)

    records = entries.map do |entry|
      record = entry[:id] ? existing_entries_by_id.fetch(entry[:id]) : BillingAdjustment.new
      record.assign_attributes(
        user_id: entry[:user_id],
        project_id: entry[:project_id],
        original_month: entry[:original_month],
        applied_month: entry[:applied_month],
        adjustment_amount: entry[:adjustment_amount],
        memo: entry[:memo]
      )
      record
    end

    invalid_record = records.find { |record| !record.valid? }
    if invalid_record
      return redirect_with_errors(
        user_id: invalid_record.errors.full_messages_for(:user_id).first || invalid_record.errors.full_messages_for(:user).first,
        project_id: invalid_record.errors.full_messages_for(:project_id).first || invalid_record.errors.full_messages_for(:project).first,
        original_month: invalid_record.errors.full_messages_for(:original_month).first,
        applied_month: invalid_record.errors.full_messages_for(:applied_month).first,
        adjustment_amount: invalid_record.errors.full_messages_for(:adjustment_amount).first,
        memo: invalid_record.errors.full_messages_for(:memo).first
      )
    end

    BillingAdjustment.transaction do
      BillingAdjustment.where(id: deleted_ids).delete_all if deleted_ids.present?
      records.each(&:save!)
    end

    redirect_to master_path, notice: "S10を保存しました"
  rescue ArgumentError => e
    redirect_with_errors(billing_adjustment: e.message)
  end

  private

  def normalize_entries(entries)
    return [] if entries.nil?
    raise ArgumentError, "保存データの形式が不正です" unless entries.is_a?(Array)

    entries.each_with_object([]) do |entry, normalized_entries|
      if entry.nil? || (entry.is_a?(String) && entry.strip == "")
        next
      end

      unless entry.is_a?(Hash) || entry.is_a?(ActionController::Parameters)
        raise ArgumentError, "保存データの形式が不正です"
      end

      normalized_entries << {
        id: parse_optional_id(entry[:id] || entry["id"]),
        user_id: parse_required_id(entry[:user_id] || entry["user_id"], "対象メンバー"),
        project_id: parse_required_id(entry[:project_id] || entry["project_id"], "対象案件"),
        original_month: parse_month(entry[:original_month] || entry["original_month"], "元の月"),
        applied_month: parse_month(entry[:applied_month] || entry["applied_month"], "反映月"),
        adjustment_amount: parse_adjustment_amount(entry[:adjustment_amount] || entry["adjustment_amount"]),
        memo: parse_memo(entry[:memo] || entry["memo"])
      }
    end
  end

  def normalize_deleted_ids(deleted_ids)
    return [] if deleted_ids.nil?
    raise ArgumentError, "削除データの形式が不正です" unless deleted_ids.is_a?(Array)

    deleted_ids.each_with_object([]) do |id, normalized_ids|
      normalized = id.is_a?(String) ? id.strip : id
      next if normalized.nil? || normalized == ""

      normalized_ids << parse_required_id(normalized, "削除対象")
    end
  end

  def parse_optional_id(value)
    return nil if value.nil?

    normalized = value.is_a?(String) ? value.strip : value
    return nil if normalized == ""

    Integer(normalized)
  rescue ArgumentError, TypeError
    raise ArgumentError, "更新対象IDの形式が不正です"
  end

  def parse_required_id(value, label)
    normalized = value.is_a?(String) ? value.strip : value
    raise ArgumentError, "#{label}の形式が不正です" if normalized.nil? || normalized == ""

    Integer(normalized)
  rescue ArgumentError, TypeError
    raise ArgumentError, "#{label}の形式が不正です"
  end

  def parse_month(value, label)
    month = value.to_s.strip
    raise ArgumentError, "#{label}の形式が不正です" unless month.match?(/\A\d{4}-\d{2}\z/)

    Date.strptime(month, "%Y-%m")
  rescue Date::Error
    raise ArgumentError, "#{label}の形式が不正です"
  end

  def parse_adjustment_amount(value)
    normalized = value.is_a?(String) ? value.strip : value
    raise ArgumentError, "調整金額は整数で入力してください" if normalized.nil? || normalized == ""

    Integer(normalized)
  rescue ArgumentError, TypeError
    raise ArgumentError, "調整金額は整数で入力してください"
  end

  def parse_memo(value)
    memo = value.to_s.strip
    raise ArgumentError, "メモは必須です" if memo.blank?

    memo
  end

  def duplicate_values?(values)
    values.uniq.length != values.length
  end

  def validate_user_and_project_existence!(entries)
    user_ids = entries.map { |entry| entry[:user_id] }.uniq
    project_ids = entries.map { |entry| entry[:project_id] }.uniq

    existing_user_ids = User.where(id: user_ids).pluck(:id)
    missing_user_id = (user_ids - existing_user_ids).first
    raise ArgumentError, "対象メンバーが存在しません（user_id: #{missing_user_id}）" if missing_user_id

    existing_project_ids = Project.where(id: project_ids).pluck(:id)
    missing_project_id = (project_ids - existing_project_ids).first
    raise ArgumentError, "対象案件が存在しません（project_id: #{missing_project_id}）" if missing_project_id
  end

  def validate_reference_editability!(entries, existing_entries_by_id)
    user_ids = entries.map { |entry| entry[:user_id] }.uniq
    project_ids = entries.map { |entry| entry[:project_id] }.uniq

    active_user_ids = User.where(id: user_ids, is_active: true).pluck(:id)
    active_project_ids = Project.where(id: project_ids, is_active: true).pluck(:id)

    entries.each do |entry|
      existing = entry[:id] ? existing_entries_by_id.fetch(entry[:id]) : nil
      reference_changed = existing.nil? ||
                          existing.user_id != entry[:user_id] ||
                          existing.project_id != entry[:project_id]
      next unless reference_changed

      unless active_user_ids.include?(entry[:user_id])
        raise ArgumentError, "無効メンバーは新規選択できません（user_id: #{entry[:user_id]}）"
      end

      unless active_project_ids.include?(entry[:project_id])
        raise ArgumentError, "終了案件は新規選択できません（project_id: #{entry[:project_id]}）"
      end
    end
  end

  def redirect_with_errors(error_hash)
    redirect_back(
      fallback_location: master_path,
      inertia: { errors: error_hash.compact }
    )
  end
end
