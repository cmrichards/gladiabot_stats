class EloChangeLineChart

  def initialize(form, elo_dates)
    @form = form
    @elo_dates = elo_dates.sort_by(&:date)
  end

  def title
    @form.opponent ? "Daily Elo Delta against #{@form.opponent.name}" : "Daily Elo Delta" 
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
