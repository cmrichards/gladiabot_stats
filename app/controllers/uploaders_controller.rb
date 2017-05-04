class UploadersController < ApplicationController

  def index
  end

  def add_players
    if params[:admin_code]!=Rails.application.secrets.admin_code
      render plain: "incorrect admin code"
      return
    end
    size = LoadFromApi.new.add_players
    render plain: "#{size} players added"
  end

  def add_games
    if params[:admin_code]!=Rails.application.secrets.admin_code
      render plain: "incorrect admin code"
      return
    end
    size = LoadFromApi.new.add_games
    render plain: "#{size} games added"
  end

end
