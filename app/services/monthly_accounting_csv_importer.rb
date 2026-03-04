# frozen_string_literal: true

require "bigdecimal"
require "csv"
require "date"

class MonthlyAccountingCsvImporter
  class ImportError < StandardError; end

  Result = Struct.new(:status, :message, :summary, :diffs, :errors, keyword_init: true)

  UTF8_BOM = "\xEF\xBB\xBF".b
  MONTH_KEY_PATTERN = /\A\d{4}-\d{2}\z/.freeze
  METRIC_LABELS = {
    sales: "売上高 計",
    gross_profit: "売上総損益金額",
    selling_general_admin_cost: "販売管理費 計",
    accounting_operating_profit: "営業損益金額"
  }.freeze
  METRIC_COLUMNS = METRIC_LABELS.keys.freeze

  def initialize(file:, confirm_overwrite_changed: false, reference_month: nil)
    @file = file
    @confirm_overwrite_changed = confirm_overwrite_changed
    @reference_month = (reference_month || default_reference_month).to_date.beginning_of_month
  end

  def call
    raise ImportError, "CSVファイルを指定してください" if file.blank?

    rows = CSV.parse(normalized_csv_text, liberal_parsing: true)
    header_info = detect_header_row(rows)
    required_rows = find_required_rows(rows, header_info[:row_index])

    extraction = extract_monthly_values(required_rows, header_info[:month_columns])
    monthly_values = extraction[:monthly_values]
    future_months = extraction[:future_months]

    raise ImportError, "取り込み対象の過去月データがありません" if monthly_values.empty?

    comparison = compare_with_existing(monthly_values)
    if comparison[:changed_diffs].any? && !confirm_overwrite_changed
      return Result.new(
        status: :confirmation_required,
        message: "既存データとの差分があります。更新しますか？",
        summary: build_preview_summary(monthly_values, future_months, comparison),
        diffs: comparison[:changed_diffs],
        errors: []
      )
    end

    import_summary = apply_import(monthly_values, future_months, comparison)
    Result.new(status: :imported, message: "会計データを取り込みました", summary: import_summary, diffs: [], errors: [])
  rescue CSV::MalformedCSVError
    Result.new(status: :error, message: "CSVの形式が不正です", summary: {}, diffs: [], errors: ["CSVの形式が不正です"])
  rescue ImportError => e
    Result.new(status: :error, message: e.message, summary: {}, diffs: [], errors: [e.message])
  end

  private

  attr_reader :file, :confirm_overwrite_changed, :reference_month

  def default_reference_month
    Time.current.in_time_zone("Asia/Tokyo").to_date
  end

  def normalized_csv_text
    raw = file.read
    file.rewind if file.respond_to?(:rewind)
    raise ImportError, "CSVファイルが空です" if raw.blank?

    binary = raw.dup.force_encoding(Encoding::BINARY)

    if binary.start_with?(UTF8_BOM)
      return binary.byteslice(UTF8_BOM.bytesize..).to_s.force_encoding(Encoding::UTF_8)
    end

    utf8 = binary.dup.force_encoding(Encoding::UTF_8)
    return utf8 if utf8.valid_encoding?

    cp932 = binary.dup.force_encoding(Encoding::Windows_31J)
    cp932.encode(Encoding::UTF_8)
  rescue Encoding::UndefinedConversionError, Encoding::InvalidByteSequenceError
    raise ImportError, "CSVの文字コードを判定できませんでした"
  end

  def detect_header_row(rows)
    rows.each_with_index do |row, index|
      month_columns = {}

      row.each_with_index do |cell, column_index|
        month_key = parse_month_key(cell)
        month_columns[column_index] = month_key if month_key
      end

      next if month_columns.empty?

      return {
        row_index: index,
        month_columns: month_columns
      }
    end

    raise ImportError, "YYYY-MM形式の月ヘッダ行が見つかりません"
  end

  def find_required_rows(rows, header_index)
    search_rows = rows[(header_index + 1)..] || []
    required_rows = {}

    METRIC_LABELS.each_value do |label|
      row = search_rows.find { |candidate| normalize_label(candidate[0]) == label }
      raise ImportError, "CSV内に「#{label}」行がありません" if row.blank?

      required_rows[label] = row
    end

    required_rows
  end

  def extract_monthly_values(required_rows, month_columns)
    monthly_values = {}
    future_months = []

    month_columns.each do |column_index, month_key|
      month_date = month_key_to_date(month_key)
      next if month_date.blank?

      month_metrics = METRIC_LABELS.each_with_object({}) do |(column_key, label), attributes|
        attributes[column_key] = parse_amount(required_rows.fetch(label)[column_index], month_key:, label:)
      end

      if month_date > reference_month
        if month_metrics.values.compact.any? { |value| !value.zero? }
          raise ImportError, "#{month_key} は未来月のため取り込めません（0または空欄のみ許可）"
        end

        future_months << month_key
        next
      end

      monthly_values[month_key] = month_metrics
    end

    { monthly_values:, future_months: future_months.sort }
  end

  def compare_with_existing(monthly_values)
    month_dates = monthly_values.keys.map { |month_key| month_key_to_date(month_key) }
    existing_by_month = MonthlyAccountingDatum.where(work_month: month_dates).index_by(&:work_month)

    comparison = {
      upsert_targets: [],
      new_month_keys: [],
      unchanged_month_keys: [],
      changed_month_keys: [],
      changed_diffs: []
    }

    monthly_values.each do |month_key, incoming_attributes|
      month_date = month_key_to_date(month_key)
      existing = existing_by_month[month_date]

      if existing.blank? || metrics_blank?(existing)
        comparison[:new_month_keys] << month_key
        comparison[:upsert_targets] << {
          month_key: month_key,
          attributes: incoming_attributes,
          existing_record: existing,
          treat_as_new: true
        }
        next
      end

      if metrics_match?(existing, incoming_attributes)
        comparison[:unchanged_month_keys] << month_key
        next
      end

      comparison[:changed_month_keys] << month_key
      comparison[:changed_diffs] << build_diff(month_key, existing, incoming_attributes)
      comparison[:upsert_targets] << {
        month_key: month_key,
        attributes: incoming_attributes,
        existing_record: existing,
        treat_as_new: false
      }
    end

    comparison
  end

  def build_preview_summary(monthly_values, future_months, comparison)
    {
      target_months: monthly_values.size,
      new_months: comparison[:new_month_keys].size,
      changed_months: comparison[:changed_month_keys].size,
      unchanged_months: comparison[:unchanged_month_keys].size,
      skipped_future_months: future_months.size
    }
  end

  def apply_import(monthly_values, future_months, comparison)
    created_count = 0
    updated_count = 0

    MonthlyAccountingDatum.transaction do
      if comparison[:upsert_targets].any?
        MonthlyAccountingDataHistory.capture!(event_type: "import")
      end

      comparison[:upsert_targets].each do |target|
        work_month = month_key_to_date(target.fetch(:month_key))
        record = target.fetch(:existing_record) || MonthlyAccountingDatum.new(work_month: work_month)
        record.assign_attributes(target.fetch(:attributes))
        record.save!

        if target.fetch(:treat_as_new)
          created_count += 1
        else
          updated_count += 1
        end
      end
    end

    {
      target_months: monthly_values.size,
      imported_months: created_count + updated_count,
      created_months: created_count,
      updated_months: updated_count,
      unchanged_months: comparison[:unchanged_month_keys].size,
      skipped_future_months: future_months.size
    }
  end

  def build_diff(month_key, existing, incoming_attributes)
    metrics = METRIC_LABELS.each_with_object([]) do |(column_key, label), rows|
      current_value = decimal_value(existing.public_send(column_key))
      incoming_value = incoming_attributes[column_key]
      next if numeric_equal?(current_value, incoming_value)

      rows << {
        key: column_key.to_s,
        label: label,
        existing: serialize_numeric(current_value),
        incoming: serialize_numeric(incoming_value)
      }
    end

    { work_month: month_key, metrics: metrics }
  end

  def parse_month_key(value)
    return nil if value.blank?

    month_key = value.to_s.strip
    return nil unless month_key.match?(MONTH_KEY_PATTERN)
    return nil if month_key_to_date(month_key).blank?

    month_key
  end

  def month_key_to_date(month_key)
    Date.strptime(month_key, "%Y-%m")
  rescue ArgumentError
    nil
  end

  def parse_amount(value, month_key:, label:)
    text = value.to_s.strip
    return nil if text.blank?

    normalized = text.delete(",")
    BigDecimal(normalized)
  rescue ArgumentError
    raise ImportError, "「#{label}」#{month_key} の値が数値ではありません"
  end

  def normalize_label(label)
    label.to_s.strip.delete_prefix("\uFEFF")
  end

  def metrics_blank?(record)
    METRIC_COLUMNS.all? { |column| record.public_send(column).nil? }
  end

  def metrics_match?(record, incoming_attributes)
    METRIC_COLUMNS.all? do |column|
      numeric_equal?(decimal_value(record.public_send(column)), incoming_attributes[column])
    end
  end

  def numeric_equal?(left, right)
    return true if left.nil? && right.nil?
    return false if left.nil? || right.nil?

    left == right
  end

  def decimal_value(value)
    return nil if value.nil?

    return value if value.is_a?(BigDecimal)

    BigDecimal(value.to_s)
  end

  def serialize_numeric(value)
    return nil if value.nil?
    return value.to_i if value.frac.zero?

    value.to_f
  end
end
