Rails.application.routes.draw do
  root "jobs#index"

  get "sign_up", to: "registrations#new", as: :sign_up
  post "sign_up", to: "registrations#create"
  resource :session
  resources :passwords, param: :token
  namespace :client do
    resources :jobs, except: %i[ show destroy ] do
      resources :proposals, only: :index do
        patch :accept, on: :member
      end
      resources :shortlists, only: %i[ index create destroy ]

      member do
        patch :publish
        patch :close
      end
    end
    resources :contracts, only: :show do
      patch :complete, on: :member
    end
  end
  namespace :freelancer do
    resources :contracts, only: :show
  end
  resources :contracts, only: [] do
    resources :reviews, only: :create
  end
  resources :jobs, only: %i[ index show ] do
    resources :proposals, only: :create
  end
  resources :clients, only: :show
  resources :freelancers, only: %i[ index show ]
  namespace :webmcp do
    resources :jobs, only: %i[ index show ]
    resources :freelancers, only: %i[ index show ]
    resources :clients, only: :show
    resources :shortlists, only: :create
    delete "shortlists", to: "shortlists#destroy"
  end
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
end
