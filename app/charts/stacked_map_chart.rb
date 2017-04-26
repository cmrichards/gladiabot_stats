class StackedMapChart
  def initialize(form, map_stats)
    @form = form
    @map_stats  = map_stats.sort_by(&:lose_percentage)
    @missions   = @map_stats.map(&:mission)
  end

  def title
    @form.opponent ? "#{@form.player.name} against #{@form.opponent.name}" : "All Maps"
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
