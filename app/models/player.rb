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

  def self.top_players(n)
    sql = "select players.id, players.name, game_players.current_elo latest_elo
          from players
          inner join game_players on game_players.player_id = players.id
          inner join games on games.id = game_players.game_id
          where games.resolution_time = 
          (
          select max(resolution_time) 
          from games
          inner join game_players on game_players.game_id = games.id and game_players.player_id = players.id
          )
          order by current_elo desc
          limit #{n}"
    Player.find_by_sql(sql)
  end

  def name
    super || "[id=#{self.id}]"
  end

end
