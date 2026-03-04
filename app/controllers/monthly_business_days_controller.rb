# frozen_string_literal: true

class MonthlyBusinessDaysController < ApplicationController
  def bulk_upsert
    entries = normalize_entries_param(params[:entries])
    return redirect_with_errors(entries: "保存対象データがありません") if entries.empty?

    normalized_entries = normalize_entries(entries)
    return redirect_with_errors(entries: "同じ月のデータが重複しています") if duplicate_entries?(normalized_entries)

    records = normalized_entries.filter_map do |entry|
      record = MonthlyBusinessDay.find_or_initialize_by(work_month: entry[:work_month])

      # 未入力(nil)は更新対象として保持し、新規nilのみスキップする
      next if record.new_record? && entry[:business_days].nil?

      record.assign_attributes(business_days: entry[:business_days])
      record
    end

    invalid_record = records.find { |record| !record.valid? }
    if invalid_record
      return redirect_with_errors(
        work_month: invalid_record.errors.full_messages_for(:work_month).first,
        business_days: invalid_record.errors.full_messages_for(:business_days).first
      )
    end

    MonthlyBusinessDay.transaction do
      records.each(&:save!)
    end

    redirect_to master_path, notice: "S6を保存しました"
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
        work_month: parse_month(entry[:work_month] || entry["work_month"]),
        business_days: parse_business_days(entry[:business_days] || entry["business_days"])
      }
    end
  end

  def parse_month(value)
    month = value.to_s.strip
    raise ArgumentError, "対象月の形式が不正です" unless month.match?(/\A\d{4}-\d{2}\z/)

    Date.strptime(month, "%Y-%m")
  rescue Date::Error
    raise ArgumentError, "対象月の形式が不正です"
  end

  def parse_business_days(value)
    return nil if value.nil?

    normalized = value.is_a?(String) ? value.strip : value
    return nil if normalized == ""

    Integer(normalized)
  rescue ArgumentError, TypeError
    raise ArgumentError, "営業日数は1〜31の整数で入力してください"
  end

  def duplicate_entries?(entries)
    keys = entries.map { |entry| entry[:work_month] }
    keys.uniq.length != keys.length
  end

  def redirect_with_errors(error_hash)
    redirect_back(
      fallback_location: master_path,
      inertia: { errors: error_hash.compact }
    )
  end
end
