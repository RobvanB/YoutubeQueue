Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
 resources :ytq_params
  # Copilot-authored: Keep the static bulk-delete path ahead of the videos/:id route.
  delete 'videos/delete_watched', to: 'videos#delete_watched', as: :delete_watched_videos
  # End Copilot-authored section.
  resources :videos

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  #get 'video/index'
  #root 'videos#index'

  # Copilot-authored: Begin routes for the updated video UI.
  # Routes retained for the existing video-data endpoint and integrations.
  Youtubequeue::Application.routes.draw do
    root :to => "videos#index"
    match "video/data", :to => "videos#data", :as => "data", :via => "get"

    get 'pull', to: 'videos#pull', as: :pull

    get 'set_watched/:id', to: 'videos#set_watched', as: :set_watched
    post 'set_filter', to: 'videos#save_filter', as: :save_video_filter

    get 'oauth2callback', to: 'videos#set_token'

    get 'set_filter/:filter', to: 'videos#set_filter'
  end
  # Copilot-authored: End routes for the updated video UI.
end
