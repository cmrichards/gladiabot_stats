class StackedPlayerGamesChart

  def initialize(form, player_stats, number_of_players: 50)
    @form = form
    @number_of_players = number_of_players
    @stats = player_stats.sort_by(&:total_games).
             reverse[0..(@number_of_players - 1)]
    @opponents = @stats.map(&:opponent)
  end

  def title
    "Top #{@number_of_players} #{@form.player.name} Played Against"
  end

  def categories
    @opponents.map(&:name)
  end

  def y_axis_title
    "Number of Games"
  end

  def series
    [
      [ "Draw", @opponents.map { |o| @stats.find{ |ms| ms.opponent.id == o.id }.draw } ],
      [ "Lose", @opponents.map { |o| @stats.find{ |ms| ms.opponent.id == o.id }.lose } ],
      [ "Win",  @opponents.map { |o| @stats.find{ |ms| ms.opponent.id == o.id }.win  } ]
    ]
  end
end
