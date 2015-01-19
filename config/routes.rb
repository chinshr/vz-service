require "sidekiq/web"

Voyzes::Application.routes.draw do
  # admin
  devise_for :admin_users, ActiveAdmin::Devise.config
  ActiveAdmin.routes(self)

  # user devise
  devise_for :users, :controllers => {:confirmations => 'confirmations'}
  devise_scope :user do
    put "/users/confirmation" => "confirmations#update", :as => :update_user_confirmation
  end

  # sidekick
  mount Sidekiq::Web, at: "/sidekiq"

  # site
  root 'web/pages#index'

  # Web::Application
  scope :module => "web", :as => "web" do
    # get '/upload' => "uploads#index"
    get '/terms/privacy-policy' => "terms#privacy_policy"
    get '/terms/terms-of-service' => "terms#terms_of_service"

    # Web:Account::Application
    get "/account" => 'account/application#index'  # => redirects /dashboard
    resource :dashboard, :only => :show, :controller => "account/dashboards"
    namespace :account do
      resource :profile, :only => [:show, :update]
      resource :billing, :only => :show
    end

    resources :documents, only: [:show, :edit], path: ""
=begin
    get "/:id" => 'documents#show'
    get "/:id/edit" => 'documents#edit'
    get "/:id/stream" => 'documents#stream'
=end
  end

  namespace :api do
    resources :tags, :only => :index do
      collection do
        get "count"
      end
    end

    resources :documents, :only => [:index, :show, :update, :destroy] do
      collection do
        get "count"
      end
      resources :tracks, :only => [:index, :show]
    end
    namespace :account do
      resources :uploads do
        collection do
          get "sign_s3"
          get "count"
        end
      end
    end
  end
end
