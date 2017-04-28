class MapStat
  attr_accessor :mission, :title, :win, :draw, :lose, :player, :elo_delta

  def initialize(player:, title:, mission:, win:, lose:, draw:, elo_delta:)
    @player = player
    @title = title
    @mission = mission
    @win = win
    @lose = lose
    @draw = draw
    @elo_delta = elo_delta
  end

  def total_games
    win + lose + draw
  end

  def lose_percentage
    lose / total_games.to_f * 100.0
  end
end
