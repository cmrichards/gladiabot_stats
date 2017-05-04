class LoadFromApi
  require "httparty"

  def add_games
    games_added = 0
    csv = HTTParty.get(Rails.application.secrets.games_api_url)
    Player.transaction do
      csv.each do |cols|
        game_id = cols[0]

        # Skip the header row and games already uploaded
        next if game_id == "id" || Game.exists?(game_id)

        games_added += 1

        player_1_elo_delta = cols[11].to_i
        player_1_elo = cols[7].to_i
        player_2_elo = cols[8].to_i
        winner_id = case cols[10]
                    when "1" then cols[5]
                    when "0" then cols[6]
                    end

        game = Game.create! do |g|
          g.id = game_id
          g.player_id = winner_id
          g.resolution_time = Time.parse(cols[2])
          g.mission_id = cols[4]
          g.draw = cols[10] == "0.5" ? 1 : 0
        end

        [
          [cols[5], cols[8], player_1_elo_delta, player_1_elo],
          [cols[6], cols[7], -player_1_elo_delta, player_2_elo]
        ].each do |player_id, opponent_elo, elo_delta, current_elo|
          xp_gained = if player_id == winner_id
                      opponent_elo.to_f
                    elsif game.draw == 1
                      opponent_elo.to_f * 0.5
                    else
                      opponent_elo.to_f * 0.25
                    end
          game.game_players.create!(player_id: player_id,
                                    xp_gained: xp_gained,
                                    elo_delta: elo_delta,
                                    current_elo: current_elo)
        end
      end
    end
    return games_added
  end

  def add_players
    if params[:admin_code]!=Rails.application.secrets.admin_code
      render plain: "incorrect admin code"
      return
    end
    csv = HTTParty.get(Rails.application.secrets.players_api_url)
    players_added = 0
    Player.transaction do
      csv.each do |cols|
        id, name = cols
        next if id == "id" || name.blank?
        if player = Player.find_by(id: id)
          player.update(name: name)
        else
          players_added += 1
          Player.create!(name: name) { |p| p.id = id }
        end
      end
    end
    return players_added
  end
end
