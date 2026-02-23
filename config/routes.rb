Rails.application.routes.draw do
  root "welcome#index"

  # Blacklight catalog routes
  concern :searchable, Blacklight::Routes::Searchable.new
  resources :catalog, only: [ :index ], controller: "catalog" do
    concerns :searchable
  end

  namespace :admin do
      resources :collections
      resources :collection_core_files
      resources :core_files do
        member do
          post :retry_processing
        end
      end
      resources :image_files
      resources :projects
      resources :project_members
      resources :users
      resources :view_packages

      root to: "projects#index"
    end

  devise_for :users, controllers: {
    sessions: "users/sessions",
    registrations: "users/registrations"
  }

  resources :projects
  resources :collections
  resources :core_files

  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
end
