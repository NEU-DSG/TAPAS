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
      resources :project_invitations, only: [ :index ] do
        member do
          patch :revoke
        end
      end
      resources :project_members do
        collection do
          get :review_queue
        end
        member do
          patch :approve
        end
      end
      resources :users
      resources :view_packages

      root to: "projects#index"
    end

  devise_for :users, controllers: {
    sessions: "users/sessions",
    registrations: "users/registrations"
  }

  # Invitation token routes (email-link driven, token as URL segment)
  get  "invitations/:token",        to: "invitations#show",   as: :invitation
  post "invitations/:token/accept", to: "invitations#accept", as: :accept_invitation

  resources :projects do
    resources :project_invitations, only: [ :create, :destroy ]
    resources :project_members, only: [ :create, :update, :destroy ] do
      member do
        patch :confirm
      end
    end
    resource :image_file, only: [ :create, :destroy ], controller: "image_files"
  end
  resources :users, only: [ :show, :edit, :update ] do
    resource :image_file, only: [ :create, :destroy ], controller: "image_files"
  end
  resources :collections do
    resources :collection_core_files, only: [ :create, :destroy ]
    resource :image_file, only: [ :create, :destroy ], controller: "image_files"
  end
  resources :core_files do
    resource :image_file, only: [ :create, :destroy ], controller: "image_files"
  end

  get "dashboard", to: "dashboard#index"

  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
end
