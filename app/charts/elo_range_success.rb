class EloRangeSuccess
  attr_accessor :elo_range,
                :lost_percentage,
                :win_percentage,
                :draw_percentage

  def self.create_elo_ranges(form)
    sql = [
      "select opponent.current_elo - (opponent.current_elo % 100)  elo_range, 
        sum(CASE WHEN games.draw=0 and games.player_id!=:player_id THEN 1.0 else 0.0 END) / count(*) * 100 lost_percentage,
        sum(CASE WHEN games.player_id=:player_id THEN 1.0 else 0.0 END) / count(*) * 100 win_percentage,
        sum(CASE WHEN games.draw = 1 THEN 1.0 else 0.0 END) / count(*) * 100 draw_percentage
      FROM games
      INNER JOIN game_players
      ON game_players.game_id    = games.id
      INNER JOIN game_players opponent
      on opponent.game_id = games.id and opponent.player_id != :player_id
      WHERE
      game_players.player_id = :player_id and
      games.mission_id in (:mission_ids) and
      games.resolution_time between :start_date and :end_date
      group by opponent.current_elo - (opponent.current_elo % 100)
      order by elo_range",
      {
        player_id:   form.player.id,
        opponent_id: form.opponent.try(:id),
        mission_ids: form.selected_missions.map(&:id),
        start_date:  form.date_range.first, end_date: form.date_range.last
      }
    ]
    Game.find_by_sql(sql).map do |row|
      EloRangeSuccess.new.tap do |er|
        er.elo_range = "#{row.elo_range}-#{row.elo_range+100}"
        er.lost_percentage = row.lost_percentage
        er.win_percentage = row.win_percentage
        er.draw_percentage = row.draw_percentage
      end
    end
  end
end
