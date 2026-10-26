Rails.application.routes.draw do
  root "saving_goals#index"

  get "/login", to: "sessions#new"
  post "/login", to: "sessions#create"
  delete "/logout", to: "sessions#destroy"

  resources :users, only: [ :new, :create ]

  resources :saving_goals, only: [ :index, :show, :new, :create ] do
    resources :memberships, only: [ :create, :destroy ]
    resources :deposits, only: [ :create ]
  end

  resources :deposits, only: [] do
    member do
      patch :confirm
      patch :reject
      patch :remand
      patch :resubmit
    end
  end

  resources :account_activations, only: [ :edit ]
end
