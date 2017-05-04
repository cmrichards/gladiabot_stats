class PlayersController < ApplicationController

  def index
    if params[:name].present? && params[:name].size > 3
      render json: Player.starts_with(params[:name]).to_json
    else
      render json: []
    end
  end

  def remember_me
    if params[:player_name].present? && player = Player.with_name(params[:player_name])
      session[:current_player_name] = params[:player_name]
      redirect_to request.referer, notice: "Remembering was successfull";
    else
      redirect_to request.referer, alert: "This is an invalid player name"
    end
  end

  def forget_me
    session[:current_player_name] = nil
    redirect_to request.referer
  end
end
