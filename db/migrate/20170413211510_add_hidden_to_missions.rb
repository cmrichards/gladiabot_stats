class AddHiddenToMissions < ActiveRecord::Migration[5.0]
  def change
    add_column :missions, :hidden, :integer, default: 0
    hide = ["Neighbours fight", "Starving", "Interference", "Ambidextrous", "Back to back"]
    Mission.where(name: hide).update_all(hidden: 1)
  end
end
