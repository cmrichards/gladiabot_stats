Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  resources :uploaders do
    collection do
      post "add_players"
      post "add_games"
    end
  end

  resources :charts

  root "uploaders#index"
end
