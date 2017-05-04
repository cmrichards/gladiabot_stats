class UploadersController < ApplicationController

  def index
  end

  def add_players
    size = LoadFromApi.new.add_players
    render plain: "#{size} players added"
  end

  def add_games
    size = LoadFromApi.new.add_games
    render plain: "#{size} games added"
  end

end
