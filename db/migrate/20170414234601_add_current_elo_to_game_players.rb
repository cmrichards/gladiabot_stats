class AddCurrentEloToGamePlayers < ActiveRecord::Migration[5.0]
  def change
    add_column :game_players, :current_elo, :float
  end
end
