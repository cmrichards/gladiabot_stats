class Game < ApplicationRecord
  belongs_to :player, required: false
  belongs_to :mission, required: false
  has_many :game_players, dependent: :destroy
  has_many :players, through: :game_players

  scope :by_resolution_time, -> { order("resolution_time desc") }

  scope :lost_or_drawn, ->(player_id) {
    where("games.draw = 1 or games.player_id!=?", player_id)
  }

  scope :for_missions, ->(mission_ids) {
    where(mission_id: mission_ids)
  }

  scope :within_date_range, ->(date_range) {
    where(resolution_time: date_range)
  }

  validates :resolution_time, :id, presence: true

  def status_f(player_id)
    if draw?
      "Draw"
    elsif winner?(player_id)
      "Win"
    else
      "Lose"
    end
  end

  def draw?
    draw == 1
  end

  def winner?(player_id)
    self.player_id == player_id
  end

  def resolution_time_f
    if resolution_time.to_date == Date.today
      resolution_time.utc.strftime("%H:%M")
    else
      resolution_time.utc.strftime "%-d %b %H:%M"
    end
  end

  def self.latest_resolution_time_for_player(player_id)
    Game.joins(:game_players).
      where(game_players: { player_id: player_id }).maximum(:resolution_time)
  end

  def self.all_games(player_id, opponent_id=nil)
    games= Game.
           select("games.*, missions.name mission_name, opponent_game_player.player_id opponent_id, opponent_game_player.current_elo opponent_elo, opponent.name opponent_name, game_players.elo_delta").
           joins(:game_players, :mission).
           joins("inner join game_players opponent_game_player on opponent_game_player.game_id = games.id").
           joins("left outer join players opponent on opponent.id = opponent_game_player.player_id").
           where(
             game_players: {
               player_id: player_id
             }
           ).
           where("opponent_game_player.player_id != ?", player_id)
    games = games.where("opponent_game_player.player_id = ?", opponent_id) if opponent_id.present?
    games
  end

end
