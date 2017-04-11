class AddMissions < ActiveRecord::Migration[5.0]
  def change
    ids = {
      220 => "The seven wonders",
      230 => "Set your priorities",
      240 => "Neighbours fight",
      250 => "Meeting point",
      251 => "Starving",
      252 => "Interference",
      253 => "Ambidextrous",
      254 => "Circle of Death",
      255 => "Split team",
      256 => "Back to back",
      2010 => "Mind Game",
      2020 => "Kingmaker",
      2030 => "Barred Spiral"
    }
    ids.each do |id, name|
      Mission.create! do |m|
        m.id = id
        m.name = name
      end
    end
  end
end
