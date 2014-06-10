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
  # get 'lmk' => 'web/pages#show'

  # Web::Application
  scope :module => "web", :as => "web" do
    get '/upload' => "uploads#index"

    # Web:Account::Application
    get "/account" => "account/application#index"
    resource :dashboard, :only => :show, :controller => "account/dashboards"
    namespace :account do
      resource :profile, :only => [:show, :update]
      resource :billing, :only => :show
    end

    get '/:id' => "documents#show"
    get '/:id/edit' => "documents#edit"
    get '/:id/stream' => "documents#stream"
  end
  
  namespace :api do
    get "/uploads/signput" => "uploads#signput"
    resources :documents, :only => [] do
      resources :tracks, :only => :index
    end
    resources :uploads
  end
  
  # post 'endpoints/email_processor' => 'griddler/emails#create'
  
  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end
