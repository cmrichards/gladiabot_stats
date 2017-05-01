class ChartsController < ApplicationController

  def index
    render layout: "fullwidth"
  end

  # GET /charts/player
  def player
    load_form
    @top_players = Player.top_players(50) if @form.invalid?
  end

  # GET /charts/player_games
  def player_games
    load_form
  end

  private

  def load_form
    @form = PlayerForm.new params[:form]
    @form.player_name = params[:player_name] if params[:player_name].present?
    @form.opponent_player_name = params[:opponent_player_name] if params[:opponent_player_name].present?
    @player_charts = PlayerCharts.new(@form) if @form.player_name.present? && @form.valid?
  end

end
