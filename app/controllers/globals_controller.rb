class GlobalsController < ApplicationController

  def maps
    @form = MapForm.new params[:form]
    if @form.valid?
      @best_on_maps = Mission.active.map do |mission|
        player_stats = Repository.best_on_map(@form, mission)
        StackedPlayerGamesChart.new(player_stats,
                                    title: mission.name,
                                    y_axis: "Percentage",
                                    max_value: 100.0)
      end
    end
  end

  def leaderboard
    player_elos = Repository.create_player_elos(start_date: Time.now - 3.weeks,
                                                end_date: Time.now + 2.hours)
    @player_elo_chart = PlayerEloChart.new(player_elos, title: "Top 20 Players Leaderboard")
  end

end
