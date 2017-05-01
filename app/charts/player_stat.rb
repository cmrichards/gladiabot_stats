class PlayerStat
  attr_reader :player,
                :opponent,
                :win, :draw, :lose,
                :elo_delta

  def initialize(player:nil, opponent:nil, win:, lose:, draw:, elo_delta:nil)
    @player = player
    @opponent = opponent
    @win = win
    @lose = lose
    @draw = draw
    @elo_delta = elo_delta
  end

  def total_games
    win + lose + draw
  end
end
