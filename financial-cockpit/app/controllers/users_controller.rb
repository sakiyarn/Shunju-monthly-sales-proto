# frozen_string_literal: true

class UsersController < ApplicationController
  def create
    user = User.new(user_params)
    password = SecureRandom.hex(16)
    user.password = password
    user.password_confirmation = password

    if user.save
      redirect_to master_path, notice: "メンバーを追加しました"
    else
      redirect_back_with_inertia_errors(user)
    end
  end

  def update
    user = User.find(params[:id])

    if user.update(user_params)
      redirect_to master_path, notice: "更新しました"
    else
      redirect_back_with_inertia_errors(user)
    end
  end

  def destroy
    user = User.find(params[:id])

    if !user.is_active
      redirect_to master_path, alert: "このメンバーは既に無効化されています"
    elsif user.update(is_active: false)
      redirect_to master_path, notice: "メンバーを無効化しました"
    else
      redirect_to master_path, alert: "メンバーを無効化できませんでした"
    end
  end

  def activate
    user = User.find(params[:id])

    if user.is_active
      redirect_to master_path, alert: "このメンバーは既に有効です"
    elsif user.update(is_active: true)
      redirect_to master_path, notice: "メンバーを再有効化しました"
    else
      redirect_to master_path, alert: "メンバーを再有効化できませんでした"
    end
  end

  private

  def user_params
    permitted = params.require(:user).permit(:name, :email, :system_role, :role_id, :display_name)
    permitted[:role_id] = nil if permitted[:role_id].blank?
    permitted[:display_name] = nil if permitted[:display_name].blank?
    permitted
  end

  def redirect_back_with_inertia_errors(user)
    redirect_back(
      fallback_location: master_path,
      inertia: { errors: user.errors.to_hash(true) }
    )
  end
end
