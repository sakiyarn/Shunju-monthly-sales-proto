# frozen_string_literal: true

require "bigdecimal"
require "date"

class MonthlyAccountingDataHistoryRestorer
  class RestoreError < StandardError; end

  SNAPSHOT_KEYS = %w[sales personnel_cost gross_profit selling_general_admin_cost accounting_operating_profit].freeze

  def initialize(history:)
    @history = history
  end

  def call
    rows = normalized_rows

    MonthlyAccountingDatum.transaction do
      MonthlyAccountingDataHistory.capture!(event_type: "restore")
      restore_rows!(rows)
    end
  rescue ActiveRecord::RecordInvalid, ArgumentError => e
    raise RestoreError, "復元に失敗しました: #{e.message}"
  end

  private

  attr_reader :history

  def normalized_rows
    Array(history.snapshot_rows).map do |row|
      normalize_row_hash(row)
    end
  end

  def normalize_row_hash(row)
    hash = row.respond_to?(:to_h) ? row.to_h : {}
    month_text = hash["work_month"] || hash[:work_month]
    raise RestoreError, "履歴データの月情報が不正です" if month_text.blank?

    {
      work_month: Date.iso8601(month_text.to_s),
      sales: decimal_or_nil(hash["sales"] || hash[:sales]),
      personnel_cost: decimal_or_nil(hash["personnel_cost"] || hash[:personnel_cost]),
      gross_profit: decimal_or_nil(hash["gross_profit"] || hash[:gross_profit]),
      selling_general_admin_cost: decimal_or_nil(hash["selling_general_admin_cost"] || hash[:selling_general_admin_cost]),
      accounting_operating_profit: decimal_or_nil(hash["accounting_operating_profit"] || hash[:accounting_operating_profit])
    }
  end

  def decimal_or_nil(value)
    return nil if value.nil?
    return nil if value.is_a?(String) && value.strip.empty?

    BigDecimal(value.to_s)
  end

  def restore_rows!(rows)
    if rows.empty?
      MonthlyAccountingDatum.delete_all
      return
    end

    target_months = rows.map { |row| row.fetch(:work_month) }
    MonthlyAccountingDatum.where.not(work_month: target_months).delete_all

    existing_by_month = MonthlyAccountingDatum.where(work_month: target_months).index_by(&:work_month)

    rows.each do |row|
      work_month = row.fetch(:work_month)
      record = existing_by_month[work_month] || MonthlyAccountingDatum.new(work_month: work_month)
      record.assign_attributes(row.except(:work_month))
      record.save!
    end
  end
end
