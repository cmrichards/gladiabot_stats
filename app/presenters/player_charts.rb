class PlayerCharts

  def initialize(player_form)
    @form = player_form
  end

  def all_games
    Game.all_games(@form.player.id, @form.opponent.try(:id)).
      for_missions(@form.selected_missions.map(&:id)).
      within_date_range(@form.date_range).
      by_resolution_time
  end

  def lost_and_drawn_games
    all_games.lost_or_drawn(@form.player.id)
  end

  def elo_range_chart
    return if @form.opponent.present?
    @ert ||= EloRangeSuccessChart.new(@form, Repository.create_elo_ranges(@form))
  end

  def player_elo_chart
    @pec ||= begin
      # Show elo change over time (and opponent's if selected)
      player_elos = Repository.create_player_elos(player_ids: [@form.player.id, @form.opponent.try(:id)].compact,
                                                  start_date: @form.date_range.first,
                                                  end_date:   @form.date_range.last,
                                                  group_by_date: false)
      PlayerEloChart.new(player_elos)
    end
  end

  def elo_change_line_chart
    @eclc ||= EloChangeLineChart.new(@form, Repository.create_elo_dates(@form))
  end

  def stacked_players_chart
    @spc||= StackedPlayerGamesChart.new(@form, player_stats)
  end

  def elo_delta_chart
    @edc ||= StackedPlayerEloDeltaChart.new(@form, player_stats, number_of_players: 50)
  end

  def individual_map_stats
    @ims ||= Repository.create_map_stats(@form)
  end

  def stacked_map_chart
    @smc ||= StackedMapChart.new(@form, individual_map_stats)
  end

  def stacked_map_chart_elo_delta
    @smced ||= StackedMapChartEloDelta.new(@form, individual_map_stats)
  end

  private

  def player_stats
    @player_stats ||= Repository.create_player_stats(@form)
  end

end
