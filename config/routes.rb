require "sidekiq/web"

Voyzes::Application.routes.draw do
  # admin
  devise_for :admin_users, ActiveAdmin::Devise.config
  ActiveAdmin.routes(self)

  # user devise
  devise_for :users, :controllers => {registrations: 'web/devise/registrations', confirmations: 'web/devise/confirmations'},
    :path_names => {:sign_in => 'sign-in', :sign_up => 'sign-up', :sign_out => 'sign-out'}
  devise_scope :user do
    put "/users/confirmation" => "web/devise/confirmations#update", :as => :update_user_confirmation
  end

  # sidekiq
  active_admin_constraint = lambda {|request| request.env["warden"].authenticate? && request.env['warden'].user && request.env['warden'].user.is_a?(AdminUser)}
  constraints active_admin_constraint do
    mount Sidekiq::Web, at: "/admin/sidekiq"
  end

  # site
  root 'web/pages#index'

  # Web::Application
  scope :module => "web", :as => "web" do
    get '/explore' => "explorers#index", as: "explore"
    get '/explore/tag/:id' => "explorers#show", as: "explore_tag"
    get '/explore/tag/:id/latest' => "explorers#show", params: {recent: true}

    get '/terms/privacy-policy' => "terms#privacy_policy"
    get '/terms/terms-of-service' => "terms#terms_of_service"

    resources :registrations, only: :create

    # Web:Account::Application
    get "/account" => 'account/application#index'  # => redirects /dashboard
    resource :dashboard, only: :show, controller: "account/dashboards"
    namespace :account do
      resource :profile, only: [:show, :update]
      resource :billing, only: [:show]
      resource :settings, only: [:show, :edit, :update]
    end

    namespace :mechanical_turk do
      resources :documents, only: [] do
        resources :chunks, only: [:new], controller: "documents/chunks"
      end
    end

    # web_document_path -> /x3ksk
    # edit_web_document_path -> /x3ksk/edit
    resources :documents, only: [:show, :edit], path: "d"

    # profile_path('@chinshr') -> /@chinshr
    # profile_document_path -> /@chinshr/x3ksk
    get '/:id', to: 'profiles#show', constraints: { id: /@([a-zA-Z0-9_]{2,15})/ }, as: :profile
    get '/:user_id/:id', to: 'profiles/documents#show', constraints: { user_id: /@[a-zA-Z0-9_]{2,15}/ }, as: :profile_document
  end

  namespace :api do
    post 'authorize/client' => 'authorization#client_authorize'
    post 'authorize/user' => 'authorization#user_authorize'
    get 'authorize/status' => 'authorization#status'
    delete 'authorize/user' => 'authorization#user_deauthorize'

    resources :tags, :only => :index do
      collection do
        get "count"
      end
    end

    resources :documents, :only => [:index, :show, :update, :destroy] do
      collection do
        get "count"
      end
      resources :tracks, :only => [:index, :show], controller: "documents/tracks"
    end

    resources :ingests, :only => [:index, :show, :update, :destroy] do
      collection do; get "count"; end
      collection do
        get "chunks" => "ingests/chunks#index"
      end
      resources :chunks, :only => [:create, :index, :show, :update, :destroy], controller: "ingests/chunks" do
        collection do
          get "count"
        end
      end
      resources :tracks, :only => [:create, :update, :index, :show, :destroy], controller: "ingests/tracks"
    end
    namespace :account do
      resources :uploads do
        collection do
          get "signed_s3_put"
          get "count"
        end
      end
    end
  end
end
