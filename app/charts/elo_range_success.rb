class EloRangeSuccess
  attr_reader :elo_range,
              :lost_percentage,
              :win_percentage,
              :draw_percentage

  def initialize(elo_range:, lost_percentage:, win_percentage:, draw_percentage:)
    @elo_range = elo_range
    @lost_percentage = lost_percentage
    @win_percentage = win_percentage
    @draw_percentage = draw_percentage
  end
end
