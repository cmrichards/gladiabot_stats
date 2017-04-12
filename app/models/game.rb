class Game < ApplicationRecord
  belongs_to :player, required: false
  belongs_to :mission, required: false
  has_many :game_players, dependent: :destroy

  def self.with_opponent(player_id)
    return if player_id.blank?
    joins("inner join game_players opp on opp.game_id = games.id").
      where("opp.player_id = ?", player_id)
  end

  def draw?
    draw == 1
  end
end
