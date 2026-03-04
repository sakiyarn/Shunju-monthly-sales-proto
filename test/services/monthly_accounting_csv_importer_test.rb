# frozen_string_literal: true

require "test_helper"

class MonthlyAccountingCsvImporterTest < ActiveSupport::TestCase
  test "imports when existing row is all nil without confirmation" do
    MonthlyAccountingDatum.create!(work_month: Date.new(2025, 7, 1))

    result = with_fixture_file("valid_accounting.csv") do |file|
      MonthlyAccountingCsvImporter.new(
        file: file,
        confirm_overwrite_changed: false,
        reference_month: Date.new(2026, 2, 1)
      ).call
    end

    assert_equal :imported, result.status

    july = MonthlyAccountingDatum.find_by!(work_month: Date.new(2025, 7, 1))
    assert_equal 1_000, july.sales.to_i
    assert_equal 400, july.gross_profit.to_i
  end

  test "returns confirmation_required when changed values exist and confirm is false" do
    MonthlyAccountingDatum.create!(
      work_month: Date.new(2025, 7, 1),
      sales: 123,
      gross_profit: 45,
      selling_general_admin_cost: 23,
      accounting_operating_profit: 22
    )

    result = with_fixture_file("valid_accounting.csv") do |file|
      MonthlyAccountingCsvImporter.new(
        file: file,
        confirm_overwrite_changed: false,
        reference_month: Date.new(2026, 2, 1)
      ).call
    end

    assert_equal :confirmation_required, result.status
    assert result.diffs.present?
  end

  test "supports utf8 bom encoded csv" do
    result = with_fixture_file("utf8_bom.csv") do |file|
      MonthlyAccountingCsvImporter.new(
        file: file,
        confirm_overwrite_changed: true,
        reference_month: Date.new(2026, 2, 1)
      ).call
    end

    assert_equal :imported, result.status
    assert_equal 3, MonthlyAccountingDatum.count
  end

  test "returns error when required row is missing" do
    result = with_fixture_file("missing_rows.csv") do |file|
      MonthlyAccountingCsvImporter.new(
        file: file,
        confirm_overwrite_changed: false,
        reference_month: Date.new(2026, 2, 1)
      ).call
    end

    assert_equal :error, result.status
    assert_match "営業損益金額", result.message
  end

  test "captures history only when import includes changes" do
    assert_difference("MonthlyAccountingDataHistory.count", 1) do
      with_fixture_file("valid_accounting.csv") do |file|
        MonthlyAccountingCsvImporter.new(
          file: file,
          confirm_overwrite_changed: true,
          reference_month: Date.new(2026, 2, 1)
        ).call
      end
    end

    assert_no_difference("MonthlyAccountingDataHistory.count") do
      with_fixture_file("valid_accounting.csv") do |file|
        MonthlyAccountingCsvImporter.new(
          file: file,
          confirm_overwrite_changed: true,
          reference_month: Date.new(2026, 2, 1)
        ).call
      end
    end
  end

  private

  def with_fixture_file(filename)
    File.open(file_fixture(filename), "rb") do |file|
      yield file
    end
  end
end
