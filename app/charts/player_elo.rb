class PlayerElo
  attr_reader :player, :elos

  class Elo
    attr_accessor :date,
                  :elo_delta
    def initialize(date:, elo_delta:)
      @date, @elo_delta = date, elo_delta
    end
  end

  def initialize(player:, elos:)
    @player = player
    @elos = elos
  end
end
