Rails.application.routes.draw do
  root "saving_goals#index"

  get "/login", to: "sessions#new"
  get "guide", to: "pages#guide", as: :guide
  post "/login", to: "sessions#create"
  delete "/logout", to: "sessions#destroy"

  resources :users, only: [ :new, :create, :edit, :update ]

  resources :saving_goals, only: [ :index, :show, :new, :create ] do
    resources :memberships, only: [ :create, :destroy ]
    resources :invitations, only: [ :create ], module: :saving_goals
    resources :deposits, only: [ :create ]
    resources :invitations, only: [ :create, :destroy ], module: :saving_goals
    resources :activities, only: [ :index ], module: :saving_goals
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
  resources :password_resets, only: [ :new, :create, :edit, :update ]

  resources :invitations, only: [ :show ] do
    post :accept, on: :member
  end

  mount LetterOpenerWeb::Engine, at: "/letter_opener" if Rails.env.development?
end
