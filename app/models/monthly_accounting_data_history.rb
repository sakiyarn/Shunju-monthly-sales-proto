# frozen_string_literal: true

class MonthlyAccountingDataHistory < ApplicationRecord
  MAX_ENTRIES = 3
  SNAPSHOT_KEYS = %i[sales personnel_cost gross_profit selling_general_admin_cost accounting_operating_profit].freeze

  validates :event_type, presence: true

  scope :recent_first, -> { order(created_at: :desc) }

  def self.capture!(event_type:)
    rows = MonthlyAccountingDatum.order(:work_month).map do |row|
      {
        "work_month" => row.work_month.iso8601
      }.merge(snapshot_value_hash(row))
    end

    history = create!(event_type:, snapshot_rows: rows)
    trim_excess!
    history
  end

  def self.trim_excess!
    stale_ids = recent_first.offset(MAX_ENTRIES).pluck(:id)
    where(id: stale_ids).delete_all if stale_ids.any?
  end

  def self.snapshot_value_hash(row)
    SNAPSHOT_KEYS.each_with_object({}) do |key, hash|
      hash[key.to_s] = serialize_decimal(row.public_send(key))
    end
  end

  def self.serialize_decimal(value)
    return nil if value.nil?
    return value.to_i if value.frac.zero?

    value.to_f
  end
end
