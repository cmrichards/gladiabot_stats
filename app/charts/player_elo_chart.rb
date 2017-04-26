class PlayerEloChart

  def initialize(player_elos)
    @player_elos = player_elos.sort_by { |pe|
      pe.elos.last.elo_delta
    }.reverse
  end

  def title
    "Historical Player Elo"
  end

  def y_axis_title
    "Elo"
  end

  def categories
    @player_elos.map(&:player).map(&:name)
  end

  def series
    @player_elos.map do |player_elo|
      [ player_elo.player.name, player_elo.elos]
    end
  end
end
