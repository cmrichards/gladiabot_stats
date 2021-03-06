Rails.application.routes.draw do
  resources :tournaments
  resources :scrapers
  resources :globals do
    collection do
      get "maps"
      get "leaderboard"
    end
  end
  resources :players do
    collection do
      post "remember_me"
      get "forget_me"
    end
  end
  resources :uploaders do
    collection do
      get "add_players"
      get "add_games"
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
