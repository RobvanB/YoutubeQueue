Rails.application.routes.draw do
  resources :ytq_params
  resources :videos

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  #get 'video/index'
  #root 'videos#index'

  # Below replaces the above so that dhtmlxgrid can be used
  Youtubequeue::Application.routes.draw do
    root :to => "videos#index"
    match "video/data", :to => "videos#data", :as => "data", :via => "get"

    get 'pull', to: 'videos#pull', as: :pull

    get 'set_watched/:id', to: 'videos#set_watched'

    get 'oauth2callback', to: 'videos#set_token'
  end
end
