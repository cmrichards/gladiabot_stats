class CreateGames < ActiveRecord::Migration[5.0]
  def change
    create_table :games do |t|
      t.datetime :resolution_time
      t.references :player
      t.references :mission, foreign_key: true
      t.integer :draw
      t.index :draw
      t.index :resolution_time
    end
  end
end
