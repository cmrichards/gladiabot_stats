class GamePlayer < ApplicationRecord
  belongs_to :player, required: false
  belongs_to :game
  validates :player_id,
            :elo_delta,
            :current_elo,
            :xp_gained, presence: true
end
