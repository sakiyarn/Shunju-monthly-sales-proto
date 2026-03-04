# frozen_string_literal: true

class MonthlyAccountingDataImportsController < ApplicationController
  def create
    importer = MonthlyAccountingCsvImporter.new(
      file: params[:file],
      confirm_overwrite_changed: ActiveModel::Type::Boolean.new.cast(params[:confirm_overwrite_changed])
    )

    result = importer.call

    case result.status
    when :imported
      render json: {
        status: "imported",
        message: result.message,
        summary: result.summary
      }
    when :confirmation_required
      render json: {
        status: "confirmation_required",
        message: result.message,
        summary: result.summary,
        diffs: result.diffs
      }
    else
      render json: {
        status: "error",
        message: result.message,
        errors: result.errors
      }, status: :unprocessable_entity
    end
  end
end
