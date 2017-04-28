Rails.application.routes.draw do
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
      get "player_games"
      get "global"
    end
  end

  get ":player_name", to: "charts#player"
  get ":player_name/vs/:opponent_player_name", to: "charts#player"

  root "charts#index"
end
