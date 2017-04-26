class EloDate
  attr_accessor :elo_delta,
                :date,
                :number_of_games

  def self.create_elo_dates(form)
    games = Game.
            select("date_trunc('day', resolution_time) date, sum(game_players.elo_delta) elo_delta, count(games.id) no_games").
            joins(:game_players).
            where(
              mission_id: form.selected_missions.map(&:id),
              game_players: {
                player_id: form.player.id
              }
            ).
            where(resolution_time: form.date_range).
            group("date_trunc('day', resolution_time)")
    if form.opponent
      games = games.joins("inner join game_players opponent_game_player on opponent_game_player.game_id = games.id").
              where("opponent_game_player.player_id = ?", form.opponent.id)
    end
    games.map do |row| 
      EloDate.new.tap do |ed|
        ed.date = row.date
        ed.elo_delta = row.elo_delta
        ed.number_of_games = row.no_games
      end
    end
  end
end
