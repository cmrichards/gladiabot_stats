class UploadersController < ApplicationController
  before_action :check_admin_code, only: [:add_players, :add_games]

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

  private

  def check_admin_code
    raise "Invalid admin code" if params[:admin_code]!=Rails.application.secrets.admin_code
  end

end
