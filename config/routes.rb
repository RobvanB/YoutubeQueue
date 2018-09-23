Rails.application.routes.draw do
  resources :ytq_params
  resources :videos

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  get 'video/index'
  get 'pull', to: 'videos#pull', as: :pull

  root 'videos#index'
end
