Rails.application.routes.draw do
  devise_for :admin_users, ActiveAdmin::Devise.config
  ActiveAdmin.routes(self)

  mount Attachinary::Engine => "/attachinary"

  devise_for :users

  root to: 'services#index'

  resources :services do
    resources :unsubs, only: :new
  end

  resources :unsubs, only: [:show] do
    member do
      get 'offers', to: "unsubs#offers"
    end
    resource :payments, only: [:new, :create]
  end

  match '/webhook/user' => 'webhooks#user', via: :post, defaults: { formats: :json }
  match '/webhook/ugc' => 'webhooks#ugc', via: :post, defaults: { formats: :json }

end
