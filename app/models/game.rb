class Game < ApplicationRecord
  belongs_to :player, required: false
  belongs_to :mission, required: false
  has_many :game_players
end
