class EloRangeSuccessChart

  def initialize(form, elo_range_successes)
    @form = form
    @elo_range_successes = elo_range_successes
  end

  def title
    "Success against Elo Ranges"
  end

  def y_axis_title
    "%"
  end

  def categories
    @elo_range_successes.map(&:elo_range)
  end

  def series
    [
      ["Draw", @elo_range_successes.map(&:draw_percentage)],
      ["Lose", @elo_range_successes.map(&:lost_percentage)],
      ["Win", @elo_range_successes.map(&:win_percentage)]
    ]
  end
end
