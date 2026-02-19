# frozen_string_literal: true

class MonthlyAccountingDataHistoriesController < ApplicationController
  def restore
    history = MonthlyAccountingDataHistory.find(params[:id])
    MonthlyAccountingDataHistoryRestorer.new(history: history).call

    render json: {
      status: "restored",
      message: "会計データを復元しました"
    }
  rescue ActiveRecord::RecordNotFound
    render json: {
      status: "error",
      message: "指定した履歴が見つかりません"
    }, status: :not_found
  rescue MonthlyAccountingDataHistoryRestorer::RestoreError => e
    render json: {
      status: "error",
      message: e.message
    }, status: :unprocessable_entity
  end
end
