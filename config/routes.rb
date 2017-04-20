Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  resources :scrapers
  resources :players
  resources :uploaders do
    collection do
      post "add_players"
      post "add_games"
    end
  end

  resources :charts do
    collection do
      get "player"
      get "global"
    end
  end

  get ":player_name", to: "charts#player"
  get ":player_name/vs/:opponent_player_name", to: "charts#player"

  root "charts#player"
end
