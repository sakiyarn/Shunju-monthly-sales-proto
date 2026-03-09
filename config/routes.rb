Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  root "pages#project_analysis"
  get "/dashboard", to: "pages#dashboard"
  get "/master", to: "master#index", as: :master
  # master-dataは削除してもいいかも
  # get "/master-data", to: "master#index"
  resources :users, only: %i[create update destroy] do
    member do
      patch :activate
      delete :hard_destroy
    end
  end
  resources :projects, only: %i[create update destroy] do
    member do
      patch :activate
      delete :hard_destroy
    end
  end
  resources :project_members, only: %i[create update destroy]
  resources :directed_expenses, only: %i[create update destroy]
  post "/billing_adjustments/bulk_sync", to: "billing_adjustments#bulk_sync"
  post "/billing_work_logs/bulk_upsert", to: "billing_work_logs#bulk_upsert"
  post "/monthly_business_days/bulk_upsert", to: "monthly_business_days#bulk_upsert"
  post "/staff_monthly_results/bulk_upsert", to: "staff_monthly_results#bulk_upsert"
  post "/staff_monthly_results/bulk_upsert_officers", to: "staff_monthly_results#bulk_upsert_officers"
  resource :monthly_accounting_data_import, only: :create
  resources :monthly_accounting_data_histories, only: [] do
    post :restore, on: :member
  end

  # Redirect to localhost from 127.0.0.1 to use same IP address with Vite server
  constraints(host: "127.0.0.1") do
    get "(*path)", to: redirect { |params, req| "#{req.protocol}localhost:#{req.port}/#{params[:path]}" }
  end
end
