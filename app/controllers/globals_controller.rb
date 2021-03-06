class GlobalsController < ApplicationController

  def maps
    @form = MapForm.new params[:form]
    if @form.valid?
      @best_on_maps = Mission.active.map do |mission|
        player_stats = Repository.best_on_map(@form, mission)
        StackedPlayerGamesChart.new(player_stats,
                                    title: mission.name,
                                    y_axis: "Percentage",
                                    max_value: 100.0,
                                    subtitle: @form.subtitle)
      end
    end
  end

  def leaderboard
    latest_game = Game.order("resolution_time").last.resolution_time.to_date
    player_elos = Repository.create_player_elos(start_date: latest_game - 5.weeks,
                                                end_date: latest_game + 2.hours)
    @player_elo_chart = PlayerEloChart.new(player_elos, title: "Top 20 Players Leaderboard")
  end

end
