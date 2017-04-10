class GamePlayer < ApplicationRecord
  belongs_to :player, required: false
  belongs_to :game
end
