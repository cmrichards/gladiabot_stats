class CreateGames < ActiveRecord::Migration[5.0]
  def change
    create_table :games do |t|
      t.datetime :resolutionTime
      t.references :player, foreign_key: true
      t.references :mission, foreign_key: true
      t.integer :eloDelta
      t.integer :xpGained
      t.integer :draw

      t.timestamps
    end
  end
end
