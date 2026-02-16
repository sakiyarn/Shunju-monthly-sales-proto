# frozen_string_literal: true

class MasterController < InertiaController
  def index
    render inertia: "Master/Index", props: {
      users: users_payload,
      roles: roles_payload
    }
  end

  private

  def users_payload
    User.ordered_for_master.map do |user|
      user.as_json(only: %i[id name email system_role role_id display_name is_active]).merge(
        role_name: user.role&.name
      )
    end
  end

  def roles_payload
    Role.order(:display_order).as_json(only: %i[id name])
  end
end
