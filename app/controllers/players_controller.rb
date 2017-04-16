class PlayersController < ApplicationController

  def index
    if params[:name].present? && params[:name].size > 3
      render json: Player.starts_with(params[:name]).to_json
    else
      render json: []
    end
  end
end
