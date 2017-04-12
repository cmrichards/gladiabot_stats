class Player < ApplicationRecord

  def self.with_name(name)
    return if name.blank?
    where(["upper(name) = upper(?)", name]).first
  end

  def name
    super || "[id=#{self.id}]"
  end

end
