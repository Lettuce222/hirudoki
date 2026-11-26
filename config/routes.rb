Rails.application.routes.draw do
  root "home#show"
  devise_for :users, only: :sessions, controllers: { sessions: "user_sessions" }
  devise_for :administrators, path: "admin", only: :sessions, controllers: { sessions: "admin/sessions" }
  namespace :admin do
    root "top#show"
    resources :orders, only: %i[index show update]
    resources :recurring_order_generations, only: %i[new create]
    resource :production_and_delivery_list, only: :show
    resources :users, only: %i[index show]
    resources :bentos, :delivery_areas, :daily_menus, except: :show
  end
  resource :registration_invitation, only: %i[new create show]
  resource :registration, only: %i[new create]
  resource :profile, only: :show
  resources :recurring_order_settings, only: %i[index new create edit update]
  resources :orders, only: %i[show edit update] do
    resource :cancellation, only: :create, controller: "order_cancellations"
    resource :review, only: %i[new create]
  end
  resources :daily_menus, only: %i[index show] do
    resources :orders, only: %i[new create]
  end

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
end
