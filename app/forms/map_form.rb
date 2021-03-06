class MapForm
  include ActiveModel::Model
  include Virtus.model

  attribute :start_date,  Date, default: ->(form, attribute) { Time.now - 14.days }
  attribute :end_date,    Date, default: ->(form, attribute) { Time.now }
  attribute :minimum_number_of_games, Integer, default: 20
  attribute :elo_range_min, Integer, default: 0
  attribute :elo_range_max, Integer, default: 3000
  attribute :top_x_players, Integer, default: 10

  validate :check_dates
  validates :start_date, :elo_range_min, :elo_range_max, :minimum_number_of_games,
            :top_x_players,
            presence: true

  def date_range
    start_date.at_beginning_of_day..end_date.end_of_day
  end

  def subtitle
    desc = ""
    if start_date.to_date == end_date.to_date
      desc << start_date.strftime("%d-%b-%y")
    else
      desc << "#{start_date.strftime("%d-%b-%y")} to #{end_date.strftime("%d-%b-%y")}"
    end
    desc
  end

  private

  def check_dates
    errors.add(:start_date, "is not a valid date") unless start_date.is_a?(Date)
    errors.add(:end_date, "is not a valid date") unless end_date.is_a?(Date)
    errors.add(:end_date, "is before the end date") if start_date.is_a?(Date) && end_date.is_a?(Date) && end_date < start_date
  end
end
