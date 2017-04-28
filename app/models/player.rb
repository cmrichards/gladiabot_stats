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
    # Find top X players with highest scores
    Player.find Game.find_by_sql(["
      select with_max_id.player_id
      from
        (select game_players.player_id, max(games.id) max_id, count(distinct games.id) no_of_games
        from games
        inner join game_players on game_players.game_id = games.id
        group by game_players.player_id) with_max_id
      inner join game_players on game_players.game_id = max_id and game_players.player_id = with_max_id.player_id
      inner join games on games.id = game_players.game_id
      where
      with_max_id.no_of_games > 1
      and games.resolution_time > ?
      order by game_players.current_elo desc
      limit #{n}
      ", Time.now - 1.week]).map(&:player_id)
  end

  def name
    super || "[id=#{self.id}]"
  end

end
