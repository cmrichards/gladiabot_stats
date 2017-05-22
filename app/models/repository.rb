class Repository

  def self.create_player_stats(player_form)
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
        player_id:   player_form.player.id,
        mission_ids: player_form.selected_missions.map(&:id),
        start_date:  player_form.date_range.first, end_date: player_form.date_range.last
      }
    ]
    Game.find_by_sql(sql).map do |row|
      PlayerStat.new(
        player: player_form.player,
        opponent: Player.new(id: row.opponent_id, name: row.opponent_name),
        win: row.win,
        lose: row.lose,
        draw: row.draw,
        elo_delta: row.elo_delta
      )
    end
  end

  def self.create_player_elos(player_ids: nil, start_date: Time.now - 3.weeks, end_date: Time.now, group_by_date: true)
    start_date = [Time.parse("16th April 2017"), start_date].max

    # Find top X players with highest scores
    player_ids = player_ids || Game.find_by_sql(["
      select with_max_id.player_id
      from
        (select game_players.player_id, max(games.id) max_id, count(distinct games.id) no_of_games
        from games
        inner join game_players on game_players.game_id = games.id
        group by game_players.player_id) with_max_id
      inner join game_players on game_players.game_id = max_id and game_players.player_id = with_max_id.player_id
      inner join games on games.id = game_players.game_id
      where
      with_max_id.no_of_games > 0
      and games.resolution_time > ?
      order by game_players.current_elo desc
      limit 20
      ", start_date]).map(&:player_id)

    sql =[
      "SELECT
        game_players.player_id,
        players.name,
        games.resolution_time,
        game_players.current_elo,
        game_players.elo_delta
      FROM
        games
        inner join game_players on game_players.game_id = games.id
        left outer join players on players.id = game_players.player_id
      WHERE
        games.resolution_time between :start_time and :end_time
        and game_players.player_id in (:player_ids)
      ",
      {
        start_time: start_date.at_beginning_of_day, end_time: end_date.end_of_day,
        player_ids: player_ids
      }
    ]
    Game.find_by_sql(sql).
      group_by(&:player_id).map do |player_id, player_rows|
      player_rows = player_rows.sort_by(&:resolution_time)
      elo = player_rows.first.current_elo
      if group_by_date
        PlayerElo.new(
          player: Player.new(id: player_id, name: player_rows.first.name),
          elos: player_rows.group_by{ |pr| pr.resolution_time.to_date }.map { |date, p_rows|
            elo += p_rows.sum(&:elo_delta)
            PlayerElo::Elo.new(date: date.to_time, elo_delta: elo)
          }
        )
      else
        PlayerElo.new(
          player: Player.new(id: player_id, name: player_rows.first.name),
          elos: player_rows.map{ |row| elo+=row.elo_delta; PlayerElo::Elo.new(date: row.resolution_time, elo_delta: elo) }
        )
      end
    end.sort_by{ |pe| pe.elos.last.elo_delta }
  end

  def self.best_on_map(map_form, mission)
    sql = [
      "
      SELECT
        players.id player_id,
        players.name player_name,
        games.mission_id,
        sum(CASE WHEN games.player_id=players.id THEN 1.0 else 0.0 END) / count(*) * 100 win,
        sum(CASE WHEN games.draw=0 and games.player_id!=players.id THEN 1.0 else 0.0 END) / count(*) * 100 lose,
        cast (SUM(games.draw)  as float) / count(*) * 100 draw 
      FROM games
      INNER JOIN game_players ON game_players.game_id = games.id
      INNER JOIN players on players.id = game_players.player_id
      WHERE
      games.mission_id  = :mission_id
      AND games.resolution_time between :start_date and :end_date
      AND game_players.current_elo between :min_elo and :max_elo
      GROUP BY players.id, players.name, games.mission_id
      having count(*) >= :minimum_number_of_games
      order by win desc
      limit :top_x_players",
      {
        mission_id: mission.id,
        start_date:  map_form.date_range.first,
        end_date: map_form.date_range.last,
        minimum_number_of_games: map_form.minimum_number_of_games,
        top_x_players: map_form.top_x_players,
        min_elo: map_form.elo_range_min,
        max_elo: map_form.elo_range_max
      }
    ]
    Game.find_by_sql(sql).map do |row|
      PlayerStat.new(
        opponent: Player.new(id: row.player_id, name: row.player_name),
        win: row.win.round(2),
        lose: row.lose.round(2),
        draw: row.draw.round(2)
      )
    end
  end

  def self.create_map_stats(player_form)
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
      #{"INNER JOIN game_players opponent ON opponent.game_id = games.id" if player_form.opponent}
      WHERE
        games.mission_id    IN (:mission_ids)
        AND game_players.player_id = :player_id
        AND games.resolution_time between :start_date and :end_date
        #{"AND opponent.player_id = :opponent_id" if player_form.opponent}
      GROUP BY games.mission_id",
      {
        player_id:   player_form.player.id,
        opponent_id: player_form.opponent.try(:id),
        mission_ids: player_form.selected_missions.map(&:id),
        start_date:  player_form.date_range.first, end_date: player_form.date_range.last
      }
    ]
    Game.find_by_sql(sql).map do |row|
      mission = player_form.selected_missions.find{ |m| m.id == row.mission_id }
      MapStat.new(
        player: player_form.player,
        title: mission.name,
        mission: mission,
        win: row.win,
        lose: row.lose,
        draw: row.draw,
        elo_delta: row.elo_delta
      )
    end
  end

  def self.create_elo_dates(player_form)
    games = Game.
            select("date_trunc('day', resolution_time) date, sum(game_players.elo_delta) elo_delta, count(games.id) no_games").
            joins(:game_players).
            where(
              mission_id: player_form.selected_missions.map(&:id),
              game_players: {
                player_id: player_form.player.id
              }
            ).
            where(resolution_time: player_form.date_range).
            group("date_trunc('day', resolution_time)")
    if player_form.opponent
      games = games.joins("inner join game_players opponent_game_player on opponent_game_player.game_id = games.id").
              where("opponent_game_player.player_id = ?", player_form.opponent.id)
    end
    games.map do |row| 
      EloDate.new(
        date: row.date,
        elo_delta: row.elo_delta,
        number_of_games: row.no_games
      )
    end
  end

  def self.create_elo_ranges(player_form)
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
        player_id:   player_form.player.id,
        opponent_id: player_form.opponent.try(:id),
        mission_ids: player_form.selected_missions.map(&:id),
        start_date:  player_form.date_range.first, end_date: player_form.date_range.last
      }
    ]
    Game.find_by_sql(sql).map do |row|
      EloRangeSuccess.new(
        elo_range: "#{row.elo_range}-#{row.elo_range+100}",
        lost_percentage: row.lost_percentage,
        win_percentage: row.win_percentage,
        draw_percentage: row.draw_percentage
      )
    end
  end

end
