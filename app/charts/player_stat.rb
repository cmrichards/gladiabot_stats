class PlayerStat
  attr_accessor :player,
                :opponent,
                :missions,
                :win, :draw, :lose,
                :elo_delta

  def self.create_player_stats(form)
    sql = [
      "SELECT 
        opponent_game_player.player_id opponent_id,
        opponent.name opponent_name,
        sum(CASE WHEN games.player_id=:player_id THEN 1 else 0 END) win,
        sum(CASE WHEN games.draw=0 and games.player_id!=:player_id THEN 1 else 0 END) lose,
        SUM(games.draw) draw,
        SUM(game_players.elo_delta) elo_delta,
        COUNT(*)
      FROM games
        INNER JOIN game_players
        ON game_players.game_id  = games.id
        INNER JOIN game_players opponent_game_player
        on opponent_game_player.game_id = games.id and opponent_game_player.player_id != :player_id
        LEFT OUTER join players opponent on opponent.id = opponent_game_player.player_id
      WHERE
        games.mission_id IN (:mission_ids) AND
        game_players.player_id = :player_id AND
        games.resolution_time between :start_date and :end_date
      GROUP BY opponent_game_player.player_id, opponent.name",
      {
        player_id:   form.player.id,
        mission_ids: form.selected_missions.map(&:id),
        start_date:  form.date_range.first, end_date: form.date_range.last
      }
    ]
    Game.find_by_sql(sql).map do |row|
      PlayerStat.new.tap do |g|
        g.player   = form.player
        g.opponent = Player.new(id: row.opponent_id, name: row.opponent_name)
        g.missions = form.selected_missions
        g.win      = row.win
        g.lose     = row.lose
        g.draw     = row.draw
        g.elo_delta= row.elo_delta
      end
    end
  end

  def total_games
    win + lose + draw
  end
end
