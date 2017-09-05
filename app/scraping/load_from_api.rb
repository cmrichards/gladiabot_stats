class LoadFromApi
  require "httparty"

  def add_games
    games_added = 0
    csv = HTTParty.get(Rails.application.secrets.games_api_url)

    headings = csv[0]
    game_id_i          = 0
    player_1_elo_delta_i = headings.index("player1EloDelta")
    player_1_init_elo_rating_i = headings.index("player1InitEloRating")
    player_2_init_elo_rating_i = headings.index("player2InitEloRating")
    actual_result_i   = headings.index("actualResult")
    player_1_id_i     = headings.index("player1ID")
    player_2_id_i     = headings.index("player2ID")
    player_1_init_elo_time_i = headings.index("player1JoinTime")
    player_2_init_elo_time_i = headings.index("player2JoinTime")
    resolution_time_i = headings.index("resolutionTime")
    creation_time_i   = headings.index("creationTime")
    mission_id_i      = headings.index("missionID")

    Player.transaction do
      csv.each_with_index do |cols, i|
        game_id = cols[game_id_i]

        # Skip the header row and games already uploaded
        next if game_id == "id" || i == 0 || Game.exists?(game_id) || cols[player_1_init_elo_time_i].blank?

        games_added += 1

        player_1_elo_delta = cols[player_1_elo_delta_i].to_i
        player_1_elo = cols[player_1_init_elo_rating_i].to_i
        player_2_elo = cols[player_2_init_elo_rating_i].to_i
        player_1_elo_time = Time.parse cols[player_1_init_elo_time_i]
        player_2_elo_time = Time.parse cols[player_2_init_elo_time_i]
        winner_id = case cols[actual_result_i]
                    when "1" then cols[player_1_id_i]
                    when "0" then cols[player_2_id_i]
                    end

        game = Game.create! do |g|
          g.id = game_id
          g.player_id = winner_id
          g.creation_time = Time.parse(cols[creation_time_i])
          g.resolution_time = Time.parse(cols[resolution_time_i])
          g.mission_id = cols[mission_id_i]
          g.draw = cols[actual_result_i] == "0.5" ? 1 : 0
        end

        [
          [cols[player_1_id_i], player_2_elo, player_1_elo_delta, player_1_elo, player_1_elo_time],
          [cols[player_2_id_i], player_1_elo, -player_1_elo_delta, player_2_elo, player_2_elo_time]
        ].each do |player_id, opponent_elo, elo_delta, current_elo, current_elo_time|
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
                                    current_elo_time: current_elo_time,
                                    current_elo: current_elo)
        end
      end
    end
    return games_added
  end

  def add_players
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
