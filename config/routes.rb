require "sidekiq/web"

Voyzes::Application.routes.draw do
  # admin
  devise_for :admin_users, ActiveAdmin::Devise.config
  ActiveAdmin.routes(self)

  # users devise
  devise_for :users,
    :controllers => {
      :registrations => 'web/devise/registrations',
      :confirmations => 'web/devise/confirmations',
      :passwords => 'web/devise/passwords',
      :unlocks => 'web/devise/unlocks',
      :sessions => 'web/devise/sessions'
    },
    :path_names => {
      :sign_in => 'sign-in',
      :sign_up => 'join',
      :sign_out => 'sign-out'
    },
    :skip => [:registrations]

  devise_scope :user do
    put "/users/confirmation" => "web/devise/confirmations#update", as: :update_user_confirmation
    get '/dashboard' => 'web/account/dashboards#show', as: :user_root # creates user_root_path for signed_in_root_path
    # manually adding routes that were skipped previously
    get '/users/join' => 'web/devise/registrations#new', as: :new_user_registration
    get '/users/cancel' => 'web/devise/registrations#cancel', as: :cancel_user_registration
    post '/users' => 'web/devise/registrations#create', as: :user_registration
    patch '/users(.:format)' => 'web/devise/registrations#update'
    put '/users(.:format)' => 'web/devise/registrations#update'
    delete '/users(.:format)' => 'web/devise/registrations#destroy'
  end

  # sidekiq
  active_admin_constraint = lambda {|request| request.env["warden"].authenticate? && request.env['warden'].user && request.env['warden'].user.is_a?(AdminUser)}
  constraints active_admin_constraint do
    mount Sidekiq::Web, at: "/admin/sidekiq"
  end

  # payola
  mount Payola::Engine => '/payola', as: :payola

  # site root
  root 'web/pages#index'

  # new home page
  get '/diecisiete' => "web/pages#diecisiete"

  # Web::Application
  scope :module => "web", :as => "web" do

    # explore
    get '/explore' => "explorers#index", as: "explore"
    get '/explore/tag/:id' => "explorers#show", as: "explore_tag"
    get '/explore/tag/:id/latest' => "explorers#show", params: {recent: true}

    # search
    get '/search' => "searches#index", as: "search"
    get '/search/users' => "searches/users#index", as: "search_users"

    # pages
    get '/pricing' => "pages#pricing"
    get '/faqs' => "pages#faqs"
    namespace :pages do
      resources :contacts, only: [:create]
    end

    # terms
    get '/terms/privacy-policy' => "terms#privacy_policy"
    get '/terms/terms-of-service' => "terms#terms_of_service"

    resources :registrations, only: :create

    # account
    get "/account" => 'account/application#index'  # => redirects /dashboard
    resource :dashboard, only: :show, controller: "account/dashboards"
    namespace :account do
      resource :profile, only: [:show, :update]
      resource :billing, only: [:show] do
        resource :subscription, only: [:show, :create, :update, :destroy]
        resource :payment_method, only: [:new, :show, :update]
      end
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
    post 'authorize/client' => 'authorization#client_authorize', as: "authorization_client_authorize"
    post 'authorize/user' => 'authorization#user_authorize', as: "authorization_user_authorize"
    get 'authorize/status' => 'authorization#status', as: "authorization_status"
    delete 'authorize/user' => 'authorization#user_deauthorize', as: "authorization_user_deauthorize"
    get 'status' => 'status#index'

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
      resources :workers, controller: "ingests/workers" do
        collection do; get "count"; end
      end
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
