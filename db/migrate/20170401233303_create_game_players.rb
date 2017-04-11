class CreateGamePlayers < ActiveRecord::Migration[5.0]
  def change
    create_table :game_players do |t|
      t.references :player, foreign_key: true
      t.references :game, foreign_key: true
      t.float :xp_gained
      t.float :elo_delta
    end
  end
end
