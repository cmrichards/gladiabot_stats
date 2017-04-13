class CreateGames < ActiveRecord::Migration[5.0]
  def change
    create_table :games do |t|
      t.datetime :resolutionTime
      t.references :player
      t.references :mission, foreign_key: true
      t.integer :draw
    end
  end
end
