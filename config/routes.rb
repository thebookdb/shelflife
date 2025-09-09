Rails.application.routes.draw do
  resources :passwords, param: :token
  mount ActionCable.server => "/cable"

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "products#index"

  # Authentication routes
  get "/signup", to: "users#new", as: :signup
  post "/signup", to: "users#create"
  get "/signin", to: "sessions#new", as: :signin
  post "/signin", to: "sessions#create"
  delete "/signout", to: "sessions#destroy", as: :signout

  # Product management routes
  resources :products, only: [ :index, :show ] do
    member do
      post :add_to_library
      delete :remove_from_library
    end
  end

  # Library management routes
  resources :libraries, only: [ :index, :show ]
  resources :library_items, only: [ :create, :destroy ]

  # Scanner routes
  get "/scanner", to: "scanners#index", as: :scanner
  get "/scanner/horizontal", to: "scanners#horizontal", as: :horizontal_scanner
  post "/scanner/set_library", to: "scanners#set_library", as: :set_scanner_library

  # Scan routes
  resources :scans, only: [ :index, :create ]

  # Users route (user management)
  resources :users, only: [ :index, :show, :new, :create ]

  # User profile routes (singular - current user)
  get "/profile", to: "user#show", as: :profile
  get "/profile/edit", to: "user#edit", as: :edit_profile
  patch "/profile", to: "user#update"
  patch "/profile/settings", to: "user#update_setting"
  patch "/profile/api_token", to: "user#update_api_token"
  delete "/profile/api_token", to: "user#delete_api_token"
  get "/profile/change_password", to: "user#change_password", as: :change_password
  patch "/profile/update_password", to: "user#update_password"

  # API routes
  namespace :api do
    namespace :v1 do
      resources :products, only: [ :show, :index ]
      resources :library_items, only: [ :index, :create, :destroy ]
      resources :scans, only: [ :index, :create ]
    end
  end

  # GTIN route - must be last to avoid conflicts
  get "/:gtin", to: "products#show", constraints: { gtin: /\d{13}/ }
end
