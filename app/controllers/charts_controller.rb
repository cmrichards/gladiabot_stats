class ChartsController < ApplicationController

  def index
    render layout: "fullwidth"
  end

  # GET /charts/player
  def player
    load_form
    if @form.player.blank?
      @top_players = Player.top_players(50) 
      if current_player
        player_elos = Repository.create_player_elos(player_ids: [current_player.id],
                                                    start_date: Date.today - 3.weeks,
                                                    end_date:   Date.tomorrow,
                                                    group_by_date: false)
        @player_elo_chart = PlayerEloChart.new(player_elos, title: nil)
      end
    end
  end

  # GET /charts/player_games
  def player_games
    load_form
  end

  private

  def load_form
    @form = PlayerForm.new params[:form]
    if params[:form].blank?
      # Passed in using special route
      @form.player_name = params[:player_name] 
      @form.opponent_player_name = params[:opponent_player_name] 
    end
    @player_charts = PlayerCharts.new(@form) if @form.player_name.present? && @form.valid?
  end

end
