class StackedPlayerEloDeltaChart
  attr_reader :title, :subtitle

  def initialize(player_stats, number_of_players: 30, title:, subtitle:nil)
    @title = title
    @subtitle = subtitle
    @number_of_players = number_of_players
    @stats = player_stats.partition{ |ps| ps.elo_delta < 0 }.
             map{ |stats| stats.sort_by{ |ps| ps.elo_delta.abs }.reverse[0..(@number_of_players/2-1)] }.
             inject(&:+)
    @opponents = @stats.map(&:opponent)
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
