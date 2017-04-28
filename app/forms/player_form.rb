class PlayerForm
  include ActiveModel::Model
  include Virtus.model

  attribute :player_name
  attribute :opponent_player_name # optional
  attribute :start_date,  Date, default: ->(form, attribute) { Time.now - 5.days }
  attribute :end_date,    Date, default: ->(form, attribute) { Time.now }
  attribute :mission_ids, Array[Integer]

  validates :player_name, :start_date, :end_date, presence: true
  validate  :check_players_names
  validate  :check_dates

  def player
    @pl ||= Player.with_name(player_name.strip) if player_name.present?
  end

  def opponent
    @op ||= Player.with_name(opponent_player_name.strip) if opponent_player_name.present?
  end

  def date_range
    start_date.at_beginning_of_day..end_date.end_of_day
  end

  def selected_missions
    @sm ||= mission_ids.blank? ? available_missions : Mission.find(mission_ids)
  end

  def available_missions
    @am ||= Mission.active
  end

  private

  def check_players_names
    errors.add(:player_name, similar_name_message(player_name)) if player.blank?
    errors.add(:opponent_player_name, similar_name_message(opponent_player_name)) if opponent_player_name.present? &&
                                                                                      opponent.blank?
  end

  def check_dates
    errors.add(:start_date, "is not a valid date") unless start_date.is_a?(Date)
    errors.add(:end_date, "is not a valid date") unless end_date.is_a?(Date)
    errors.add(:end_date, "is before the end date") if start_date.is_a?(Date) && end_date.is_a?(Date) && end_date < start_date
  end

  def similar_name_message(name)
    message = "does not exist."
    if name.present?
      similar_players = Player.similar_to(name).limit(50).by_name.to_a || Player.similar_to(name.split.first).by_name.limit(50).to_a
      if similar_players.any?
        message << " These similar players exist: "
        message << similar_players.map(&:name).join(", ")
      end
    end
    message
  end
end
