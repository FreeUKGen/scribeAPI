API::Application.routes.draw do

  root :to => "home#index"

  devise_for :users, :controllers => {:registrations => "registrations",
                                      :omniauth_callbacks => "omniauth_callbacks",
                                      :sessions => "sessions"}


  get '/projects',        to: 'projects#index', defaults: { format: 'json' }

  get '/workflows',      to: 'workflow#index', defaults: { format: 'json' }
  get '/workflows/:id',  to: 'workflow#show',  defaults: { format: 'json' }
  get '/dashboard',      to: 'dashboard#index'
  get '/projects/stats', to: 'projects#stats'



  get '/project/style.css',   to: 'projects#project_css', defaults: { format: 'css' }


  get '/workflows/:workflow_id/subjects' => 'subjects#index'
  get '/workflows/:workflow_id/subject_sets' => 'subject_sets#index'
  get '/subjects/:subject_id', to: 'subjects#show', defaults: { format: 'json'}

  resources :favourites, defaults: {format: 'json'}

  post   '/subjects/:id/favourite', to: 'favourites#create', defaults: { format: 'json'}
  post   '/subjects/:id/unfavourite', to: 'favourites#destroy', defaults: {format:'json'}

  resources :subjects, :defaults => { :format => 'json' }
  resources :subject_sets, :defaults => { :format => 'json' }
  get '/classifications/terms/:workflow_id/:annotation_key', to: 'classifications#terms'
  resources :classifications, :defaults => { :format => 'json' }
  resources :groups, :defaults => { :format => 'json' }


  get  '/current_user' => "users#logged_in_user"
  resources :favourites, only: [:index, :create, :destroy]
end
