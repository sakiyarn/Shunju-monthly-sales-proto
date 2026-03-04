# frozen_string_literal: true

class PagesController < InertiaController
  def project_analysis
    render inertia: 'ProjectAnalysis/Index'
  end

  def dashboard
    render inertia: 'Dashboard/Index'
  end
end
