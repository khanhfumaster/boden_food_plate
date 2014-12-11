Rails.application.routes.draw do
  get 'search/index'
  get 'search/query'

  root to: 'visitors#index'
  devise_for :users
  resources :users

  get '/foods' => 'food_categories#index', :as => 'food_categories'
  get '/categories/:id' => 'food_categories#show', :as => 'food_category'
end


