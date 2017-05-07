class AddCurrentEloTimeToGamePlayers < ActiveRecord::Migration[5.1]
  def change
    add_column :game_players, :current_elo_time, :datetime
    add_column :games, :creation_time, :datetime
  end
end
