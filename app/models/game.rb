class Game < ApplicationRecord
  belongs_to :player, required: false
  belongs_to :mission, required: false
  has_many :game_players, dependent: :destroy

  def draw?
    draw == 1
  end

  def self.lost_or_drawn(player_id)
    Game.select("games.*, missions.name mission_name, opponent_game_player.player_id opponent_id, opponent.name opponent_name, game_players.elo_delta").
         joins(:game_players, :mission).
         joins("inner join game_players opponent_game_player on opponent_game_player.game_id = games.id").
         joins("left outer join players opponent on opponent.id = opponent_game_player.player_id").
         where(
            game_players: {
              player_id: player_id
            }
         ).
         where("opponent_game_player.player_id != ?", player_id).
         where("games.draw = 1 or games.player_id!=?", player_id)
  end
end
