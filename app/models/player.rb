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

  # Find top X players with highest scores
  def self.top_players(n)
    Player.find_by_sql(["
      select players.id, players.name
      from
        (select game_players.player_id, max(games.id) max_id, count(distinct games.id) no_of_games
        from games
        inner join game_players on game_players.game_id = games.id
        group by game_players.player_id) with_max_id
      inner join game_players on game_players.game_id = max_id and game_players.player_id = with_max_id.player_id
      inner join games on games.id = game_players.game_id
      inner join players on game_players.player_id = players.id
      where
      with_max_id.no_of_games > 1
      and games.resolution_time > ?
      order by game_players.current_elo desc
      limit #{n}
      ", Time.now - 2.week])
  end

  def name
    super || "[id=#{self.id}]"
  end

end
