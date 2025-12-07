Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Authentication routes
  get "login", to: "sessions#new", as: :login
  post "login", to: "sessions#create"
  delete "logout", to: "sessions#destroy", as: :logout

  # Password setup routes
  get "password/setup", to: "passwords#new", as: :password_setup
  post "password/setup", to: "passwords#create"
  get "password/request_new", to: "passwords#request_new", as: :request_new_password

  resources :templates, only: %i[index create edit update destroy]
  get "gerenciamento/templates", to: "templates#index", as: :management_templates
  resources :avaliacoes, only: %i[index create]
  resources :resultados, only: %i[index show] do
    member do
      get :export
    end
  end
  
  root "sessions#new"

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  #Sigaa Import routes
  resources :sigaa_imports, only: [:new, :create, :index]
end
