class StackedMapChartEloDelta

  def initialize(form, map_stats)
    @form = form
    @map_stats  = map_stats.sort_by(&:lose_percentage)
    @missions   = @map_stats.map(&:mission)
  end

  def title
    "Elo Delta for " + (@form.opponent ? "#{@form.player.name} against #{@form.opponent.name}" : "All Maps")
  end

  def categories
    ["Total"] + @missions.map(&:name)
  end

  def y_axis_title
    "Elo"
  end

  def series
    total_elo_delta = @map_stats.sum(&:elo_delta)
    [
      [ "Elo Delta", [total_elo_delta] + @missions.map { |m| @map_stats.find{ |ms| ms.mission == m }.elo_delta } ]
    ]
  end
end