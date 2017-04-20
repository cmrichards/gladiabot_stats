class ScrapersController < ApplicationController
  require "scrape_games"
  require "scraped_game_creator"

  def index
  end

  def create
    if params[:player_name].present?
      matches = ScrapeGames.new.fetch_user_matches(params[:player_name])
    else
      matches = ScrapeGames.new.fetch_league_latest_matches
    end
    game_creator = ScrapedGameCreator.new(matches)
    if game_creator.valid?
      game_creator.create_games!(skip_games_with_missing_players: true)
      if params[:player_name].present?
        redirect_to player_charts_url(form: { player_name: params[:player_name] }),
                    notice: "Recent game data for #{params[:player_name]} was loaded."
      else
        redirect_to player_charts_url, notice: "Recent league data was loaded."
      end
    else
      @errors = game_creator.errors
      render "index"
    end
  end
end
