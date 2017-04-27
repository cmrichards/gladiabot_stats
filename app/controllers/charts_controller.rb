class ChartsController < ApplicationController

  def index
    render layout: "fullwidth"
  end

  # GET /charts/player

  def player
    load_form
  end

  # GET /charts/player_games

  def player_games
    load_form
  end

  # GET /charts/global

  def global
    @form = PlayerForm.new
    player_elos = PlayerElo.create_player_elos(start_date: Time.now - 3.weeks, end_date: Time.now + 2.hours)
    @player_elo_chart = PlayerEloChart.new(player_elos, title: "Top 20 Players Leaderboard")
  end

  private

  def load_form
    @form = PlayerForm.new params[:form]
    @form.player_name = params[:player_name] if params[:player_name].present?
    @form.opponent_player_name = params[:opponent_player_name] if params[:opponent_player_name].present?
    @player_charts = PlayerCharts.new(@form) if @form.player_name.present? && @form.valid?
  end


end
