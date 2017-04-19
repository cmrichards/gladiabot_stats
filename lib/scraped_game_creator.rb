class ScrapedGameCreator
  attr_reader :errors

  def initialize(scraped_matches)
    @scraped_matches = scraped_matches
    @errors = []
  end

  def valid?
    @errors = []

    map_names = @scraped_matches.map(&:map_name).uniq
    missions = Mission.where("upper(name) in (?)", map_names.map(&:upcase)).to_a
    @errors << "These missions are missing from the database: #{(map_names - missions.map(&:name)).join(", ")}" if missions.size != map_names.size

    if @scraped_matches.any?{ |m| m.id.blank? }
      @errors << "Some matches have no id"  
    else
      matches = @scraped_matches.select{ |m| !m.time.between?(Time.now - 8.weeks, Time.now+1.hour) }
      @errors << "These matches are not within last 8 weeks: #{matches.map(&:id).join(", ")}" if matches.any?
      invalid_match_results = @scraped_matches.select{ |m|
        (m.draw && m.players.any?(&:winner) ) || (!m.draw && m.players.none?(&:winner) ) || m.players.all?(&:winner)
      }
      @errors << "These matches have incorrect results: #{invalid_match_results.map(&:id).join(", ")}" if @scraped_matches.all?{ |m| m.id.present? } &&
                                                                                                          invalid_match_results.any?
      invalid_player_details = @scraped_matches.select{ |m|
        m.players.any?{ |p| p.name.blank? || p.elo.blank? || p.elo_delta.blank? }
      }
      @errors << "These matches contain invalid player data: #{invalid_player_details.map(&:id).join(", ")}" if invalid_player_details.any?
    end

    @errors.empty?
  end

  # skip_games_with_missing_players: If set to true, then games with unknown players
  # will be ignored.  Use this if the player dump should be the only source of
  # new players

  def create_games!(skip_games_with_missing_players: true)
    raise "Errors exist" if !valid?
    Game.transaction do
      @scraped_matches.
        select { |match| !Game.exists?(match.id) }.
        each { |match|
        new_game = Game.new do |game|
          game.id = match.id
          game.mission = Mission.find_by(name: match.map_name)
          game.resolution_time = match.time
          game.draw = match.draw ? 1 : 0
          game.game_players = match.players.map { |player|
            opponent_elo = match.players.find{ |p| p != player }.elo
            GamePlayer.new do |gp|
              existing_player = Player.with_name(player.name)
              next if existing_player.nil? && skip_games_with_missing_players
              gp.player     = existing_player || Player.create!(name: player.name)
              game.player_id= gp.player.id if player.winner
              gp.current_elo= player.elo
              gp.elo_delta  = player.elo_delta
              gp.xp_gained  = if player.winner
                               opponent_elo.to_f
                             elsif match.draw 
                               opponent_elo.to_f * 0.5
                             else
                               opponent_elo.to_f * 0.25
                             end
            end
          }
        end
        new_game.save!
      }
    end
  end

end
