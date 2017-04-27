class PlayerElo

  attr_accessor :player, :elos

  class Elo
    attr_accessor :date,
                  :position,
                  :elo_delta
  end

  def self.create_player_elos(player_ids: nil, start_date: Time.now - 3.weeks, end_date: Time.now)
    start_date = [Time.parse("16th April 2017"), start_date].max
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
      with_max_id.no_of_games > 1
      and games.resolution_time > ?
      order by game_players.current_elo desc
      limit 20
      ", Time.now - 1.week]).map(&:player_id)

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
      PlayerElo.new.tap do |pe|
        pe.player = Player.new(id: player_id, name: player_rows.first.name)
        pe.elos = player_rows.group_by{ |pr| pr.resolution_time.to_date }.map { |date, p_rows|
          elo += p_rows.sum(&:elo_delta)
          PlayerElo::Elo.new.tap do |pe| 
            pe.date = date
            pe.elo_delta = elo
          end
        }
      end
    end.sort_by{ |pe| pe.elos.last.elo_delta }
  end
end
