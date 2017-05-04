class StackedMapChart
  attr_reader :title, :subtitle

  def initialize(map_stats, title:, subtitle: nil)
    @title = title
    @subtitle = subtitle
    @map_stats  = map_stats.sort_by(&:lose_percentage)
    @missions   = @map_stats.map(&:mission)
  end

  def to_partial_path
    "charts/stacked_bar_chart"
  end

  def categories
    @missions.map(&:name)
  end

  def y_axis_title
    "Number of Games"
  end

  def series
    [
      [ "Draw", @missions.map { |m| @map_stats.find{ |ms| ms.mission == m }.draw } ],
      [ "Lose", @missions.map { |m| @map_stats.find{ |ms| ms.mission == m }.lose } ],
      [ "Win",  @missions.map { |m| @map_stats.find{ |ms| ms.mission == m }.win  } ]
    ]
  end
end
