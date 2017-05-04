class StackedPlayerGamesChart
  attr_reader :subtitle

  def initialize(player_stats, title:,
                 number_of_players: 50,
                 y_axis: "Number",
                 max_value: nil,
                 subtitle: nil)
    @subtitle = subtitle
    @max_value = max_value
    @y_axis = y_axis
    @title = title
    @number_of_players = number_of_players
    @stats = player_stats
    @opponents = @stats.map(&:opponent)
  end

  def title
    @title
  end

  def categories
    @opponents.map(&:name)
  end

  def y_axis_title
    @y_axis
  end

  def max_value
    @max_value
  end

  def series
    [
      [ "Draw", @opponents.map { |o| @stats.find{ |ms| ms.opponent.id == o.id }.draw } ],
      [ "Lose", @opponents.map { |o| @stats.find{ |ms| ms.opponent.id == o.id }.lose } ],
      [ "Win",  @opponents.map { |o| @stats.find{ |ms| ms.opponent.id == o.id }.win  } ]
    ]
  end
end
