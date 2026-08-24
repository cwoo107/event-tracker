Rails.application.routes.draw do
  # From `bin/rails generate authentication` (see the domain-model phase README) -
  # SessionsController/PasswordsController and their views aren't part of this
  # deliverable, only the routes needed for Authentication#require_authentication
  # (new_session_path) to resolve.
  resource :session, only: [:new, :create, :destroy]
  resource :registration, only: [:new, :create]
  resources :passwords, param: :token, only: [:new, :create, :edit, :update]

  root "events#map"
  get "map", to: "events#map", as: :map

  resources :events, only: [:show, :new, :create, :edit, :update] do
    member do
      get :candidates
      post :auto_assign
      post :assign_candidate
      post :unassign
      post :complete
    end
  end

  resource :settings, only: [:edit, :update]
  post "settings/reset", to: "settings#reset", as: :reset_settings

  resources :liaisons
  get "dashboard", to: "dashboard#index", as: :dashboard
  get "calendar", to: "calendar#index", as: :calendar
  get "requests", to: "requests#index", as: :requests
end
