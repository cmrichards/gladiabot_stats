class EloDate
  attr_reader :elo_delta,
              :date,
              :number_of_games

  def initialize(elo_delta:, date:, number_of_games:)
    @elo_delta = elo_delta
    @date = date
    @number_of_games = number_of_games
  end
end
