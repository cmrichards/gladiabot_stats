class UploadersController < ApplicationController
  require "csv"

  def index ; end

  def add_players
    Player.transaction do
      CSV.parse(params[:file].read).each do |cols|
        id, name = cols
        next if id == "id" || name.blank?

        if player = Player.find_by(id: id)
          player.update(name: name)
        else
          Player.create!(name: name) { |p| p.id = id }
        end
      end
    end
    render text: "Players were added/updated", layout: false
  end

  def add_games
    file = params[:file].read.encode!(universal_newline: true) # fix strange newlines
    Game.transaction do
      CSV.parse(file).each do |cols|
        game_id = cols[0]
        next if game_id == "id" || Game.exists?(game_id)

        player_1_elo_delta = cols[11].to_i
        winner_id = case cols[10]
                    when "1" then cols[5]
                    when "0" then cols[6]
                    end

        game = Game.create!({
          id:             game_id,
          resolutionTime: Time.parse(cols[2]),
          mission_id:     cols[4],
          player_id:      winner_id,
          draw:           cols[10] == "0.5" ? 1 : 0
        }, without_protection: true) 

        game = Game.create! do |g| 
          g.id = game_id
          g.resolutionTime = Time.parse(cols[2])
          g.mission_id = cols[4]
          g.draw = cols[10] == "0.5" ? 1 : 0
            p
        end

        [
         [cols[5], cols[8], player_1_elo_delta],
         [cols[6], cols[7], -player_1_elo_delta]
        ].each do |player_id, opponent_elo, elo_delta|
          xp_gained = if player_id == winner_id
                       opponent_elo.to_f
                     elsif game.draw == 1
                       opponent_elo.to_f * 0.5
                     else
                       opponent_elo.to_f * 0.25
                     end
          game.game_players.create!(player_id: player_id,
                                    xp_gained: xp_gained,
                                    elo_delta: elo_delta)
        end
      end
    end
    render text: "Games were added", layout: false
  end

  private

  def no_file_error
    render text: "You didn't select a file!", layout: false
  end

  class MissingFile < StandardError ; end

  rescue_from MissingFile, with: :no_file_error


end
