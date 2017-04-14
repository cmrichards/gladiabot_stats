class Player < ApplicationRecord

  scope :similar_to, -> (player_name) {
    where("upper(name) like ?", "%#{player_name.upcase}%")
  }

  scope :starts_with, -> (player_name) {
    where("upper(name) like ?", "#{player_name.upcase}%")
  }

  scope :by_name, -> { order("upper(name)") }

  def self.with_name(name)
    return if name.blank?
    where(["upper(name) = upper(?)", name]).first
  end

  def name
    super || "[id=#{self.id}]"
  end

end
