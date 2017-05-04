class EloChangeLineChart
  attr_reader :subtitle

  def initialize(elo_dates, subtitle: nil)
    @subtitle = subtitle
    @elo_dates = elo_dates.sort_by(&:date)
  end

  def title
    "Daily Elo Delta"
  end

  def y_axis_title
    "Elo Delta"
  end

  def series
    [
      ["Elo Delta", @elo_dates ]
    ]
  end
end
