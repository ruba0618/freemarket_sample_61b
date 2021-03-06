Rails.application.routes.draw do
  devise_for :users, controllers: {
    omniauth_callbacks: 'users/omniauth_callbacks',
    registrations: 'users/registrations',
    sessions: 'users/sessions'
  }

  devise_scope :user do
    get 'user_regist', to: 'users/registrations#step1'
    post 'user_regist', to: 'users/registrations#step1_regist'
    get 'phone_regist', to: 'users/registrations#step2'
    post 'phone_regist', to: 'users/registrations#step2_regist'
    get 'phone_confirm', to: 'users/registrations#phone_confirm'
    post 'phone_confirm', to: 'users/registrations#phone_confirm_input'
    get 'destination_regist', to: 'users/registrations#step3'
    post 'destination_regist', to: 'users/registrations#step3_regist'
    get 'creditcard_regist', to: 'users/registrations#step4'
    post 'creditcard_regist', to: 'users/registrations#step4_regist'
    get 'registed', to: 'users/registrations#finish_regist'
  end
  resources :categories, only: [:index, :show]
  get 'brands/group/:id', to: 'brands#group_show', as: :brand_group

  resources :brands, only: [:show] do
    get ':id', to: 'brands#category'
  end

  get 'products/search'
  get 'products/detail_search'
  resources :products do
    collection do
      get 'get_category_children', defaults: { format: 'json' }
      get 'get_category_grandchildren', defaults: { format: 'json' }
      get 'get_size', defaults: { format: 'json' }
      get 'get_delivery_method', defaults: { format: 'json' }
    end
  end

  root to: "products#index"
  get 'users/logout'

  resources :users, only: [:show, :edit] do
    resources :credit_cards, only: [:show]
    resources :products,only: [:edit, :update]
    get'listing_sale', to: 'users#listing_sale'
    get'listing_trade', to: 'users#listing_trade'
    get'listing_soldout', to: 'users#listing_soldout'
  end
  
  resources :products do
    member do
      post 'buy', to: 'credit_cards#buy'
      get 'done'
    end
  end

end
