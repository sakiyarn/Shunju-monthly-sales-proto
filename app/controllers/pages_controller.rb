# frozen_string_literal: true

class PagesController < InertiaController
  def project_analysis
    render inertia: 'ProjectAnalysis/Index'
  end

  def dashboard
    projects = Project
      .ordered_for_master
      .where(is_active: true)
      .as_json(only: %i[id name is_active display_order])
    
    users = User
      .ordered_for_master
      .where(is_active: true)
      .as_json(only: %i[id name display_name is_active system_role])

    render inertia: 'Dashboard/Index', props: {
      projects: projects,
      users: users
    }
  end
end
