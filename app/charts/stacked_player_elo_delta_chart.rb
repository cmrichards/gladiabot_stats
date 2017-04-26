class StackedPlayerEloDeltaChart

  def initialize(form, player_stats, number_of_players: 30)
    @number_of_players = number_of_players
    @form = form
    @stats = player_stats.partition{ |ps| ps.elo_delta < 0 }.
             map{ |stats| stats.sort_by{ |ps| ps.elo_delta.abs }.reverse[0..(@number_of_players/2-1)] }.
             inject(&:+)
    @opponents = @stats.map(&:opponent)
  end

  def title
    "Top #{@number_of_players} #{@form.player.name} Elo Delta"
  end

  def categories
    @opponents.map(&:name)
  end

  def y_axis_title
    "Elo"
  end

  def series
    [
      [ "Elo Delta",  @opponents.map { |o| @stats.find{ |ms| ms.opponent.id == o.id }.elo_delta  } ]
    ]
  end
end
