class MapStat
  attr_accessor :mission, :title, :win, :draw, :lose, :player, :elo_delta

  def self.create_map_stats(form)
    sql = [
      "SELECT
        games.mission_id,
        sum(CASE WHEN games.player_id=:player_id THEN 1 else 0 END) win,
        sum(CASE WHEN games.draw=0 and games.player_id!=:player_id THEN 1 else 0 END) lose,
        SUM(games.draw) draw,
        SUM(game_players.elo_delta) elo_delta,
        COUNT(*) total
      FROM games
      INNER JOIN game_players ON game_players.game_id = games.id
      #{"INNER JOIN game_players opponent ON opponent.game_id = games.id" if form.opponent}
      WHERE
        games.mission_id    IN (:mission_ids)
        AND game_players.player_id = :player_id
        AND games.resolution_time between :start_date and :end_date
        #{"AND opponent.player_id = :opponent_id" if form.opponent}
      GROUP BY games.mission_id",
      {
        player_id:   form.player.id,
        opponent_id: form.opponent.try(:id),
        mission_ids: form.selected_missions.map(&:id),
        start_date:  form.date_range.first, end_date: form.date_range.last
      }
    ]
    Game.find_by_sql(sql).map do |row|
      mission = form.selected_missions.find{ |m| m.id == row.mission_id }
      MapStat.new.tap do |g|
        g.player  = form.player
        g.title   = mission.name
        g.mission = mission
        g.win     = row.win
        g.lose    = row.lose
        g.draw    = row.draw
        g.elo_delta= row.elo_delta
      end
    end
  end

  def total_games
    win + lose + draw
  end

  def lose_percentage
    lose / total_games.to_f * 100.0
  end
end
