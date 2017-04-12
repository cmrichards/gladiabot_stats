class ChartsController < ApplicationController

  # GET /charts

  def index
    @form = Form.new params[:form]
    if params[:form] && @form.valid?
      player_stats  = PlayerStat.create_player_stats(@form)
      @stacked_players = StackedPlayerGamesChart.new(@form, player_stats)
      @stacked_players_elo_delta = StackedPlayerEloDeltaChart.new(@form, player_stats,
                                                                  number_of_players: 50)

      @stacked_map = StackedMapChart.new(@form)
      @map_stats   = @stacked_map.map_stats
    end
  end

  def global
  end

  private

  # TODO: move these classes somewhere sensible...
 
  class Form
    include ActiveModel::Model
    include Virtus.model

    attribute :player_name
    attribute :opponent_player_name # optional
    attribute :start_date,  Date, default: Time.now - 2.weeks
    attribute :end_date,    Date, default: Time.now
    attribute :mission_ids, Array[Integer]

    validates :player_name, :start_date, :end_date, presence: true
    validate  :check_players_names
    validate  :check_dates

    def player
      @pl ||= Player.with_name(player_name)
    end

    def opponent
      @op ||= Player.with_name(opponent_player_name) if opponent_player_name.present?
    end

    def date_range
      start_date.at_beginning_of_day..end_date.end_of_day
    end

    def selected_missions
      mission_ids.blank? ? available_missions : Mission.find(mission_ids)
    end

    def available_missions
      Mission.all
    end

    private

    def check_players_names
      errors.add(:player_name, "does not exist") if player.blank?
      errors.add(:opponent_player_name, "does not exist") if opponent_player_name.present? && opponent.blank?
    end

    def check_dates
      errors.add(:start_date, "is not a valid date") unless start_date.is_a?(Date)
      errors.add(:end_date, "is not a valid date") unless end_date.is_a?(Date)
      errors.add(:end_date, "is before the end date") if start_date.is_a?(Date) && end_date.is_a?(Date) && end_date < start_date
    end
  end

  class StackedMapChart
    attr_reader :map_stats

    def initialize(form)
      @form = form
      @map_stats  = @form.selected_missions.
                          map { |mission| MapStat.create_map_stat(mission, form) }.
                          select(&:has_games?).
                          sort_by(&:lose_percentage)
      @missions   = @map_stats.map(&:mission)
    end

    def title
      @form.opponent ? "All Maps between #{@form.player.name} and #{@form.opponent.name}" : "All Maps"
    end

    def categories
      @missions.map(&:name)
    end

    def series
      [
        [ "Draw", @missions.map { |m| @map_stats.find{ |ms| ms.mission == m }.draw } ],
        [ "Lose", @missions.map { |m| @map_stats.find{ |ms| ms.mission == m }.lose } ],
        [ "Win",  @missions.map { |m| @map_stats.find{ |ms| ms.mission == m }.win  } ]
      ]
    end
  end

  class StackedPlayerGamesChart

    def initialize(form, player_stats, number_of_players: 50)
      @form = form
      @number_of_players = number_of_players
      @stats = player_stats.sort_by(&:total_games).
                            reverse[0..(@number_of_players - 1)]
      @opponent_ids = @stats.map(&:opponent_id)
    end

    def title
      "Top #{@number_of_players} #{@form.player.name} Played Against"
    end

    def categories
      @opponent_ids.map do |player_id|
        Player.find_by(id: player_id).try(:name) || "[id=#{player_id}]"
      end
    end

    def series
      [
        [ "Draw", @opponent_ids.map { |id| @stats.find{ |ms| ms.opponent_id == id }.draw } ],
        [ "Lose", @opponent_ids.map { |id| @stats.find{ |ms| ms.opponent_id == id }.lose } ],
        [ "Win",  @opponent_ids.map { |id| @stats.find{ |ms| ms.opponent_id == id }.win  } ]
      ]
    end
  end

  class StackedPlayerEloDeltaChart

    def initialize(form, player_stats, number_of_players: 30)
      @number_of_players = number_of_players
      @form = form
      @stats = player_stats.sort_by{ |ps| ps.elo_delta.abs }.
                            reverse[0..(@number_of_players - 1)]
      @opponent_ids = @stats.map(&:opponent_id)
    end

    def title
      "Top #{@number_of_players} #{@form.player.name} Elo Delta"
    end

    def categories
      @opponent_ids.map do |player_id|
        Player.find_by(id: player_id).try(:name) || "[id=#{player_id}]"
      end
    end

    def series
      [
        [ "Elo Delta",  @opponent_ids.map { |id| @stats.find{ |ms| ms.opponent_id == id }.elo_delta  } ]
      ]
    end
  end

  class PlayerStat
    attr_accessor :player,
                  :opponent_id,
                  :missions,
                  :win, :draw, :lose,
                  :elo_delta

    def self.create_player_stats(form)
      games = Game.joins(:game_players).
                   includes(:game_players => :player).
                   where(
                     mission_id:     form.selected_missions.map(&:id),
                     resolutionTime: form.date_range,
                     game_players:   {
                       player_id: form.player.id
                     }
                   )

      # Group all games for this player by opponent player id 
      games.
        group_by { |game| game.game_players.find{ |gp| gp.player_id != form.player.id }.player_id }.
        map { |opponent_id, games|
          PlayerStat.new.tap do |g|
            g.player   = form.player
            g.opponent_id = opponent_id
            g.missions = form.selected_missions
            g.win      = games.select{ |g| g.player_id == form.player.id }.size
            g.lose     = games.select{ |g| g.player_id.present? && g.player_id != form.player.id }.size
            g.draw     = games.select{ |g| g.draw == 1 }.size
            g.elo_delta = games.sum { |g|
              g.game_players.find{ |gp| gp.player_id == form.player.id }.elo_delta
            }
          end
        }
    end

    def total_games
      win + lose + draw
    end
  end

  class MapStat
    attr_accessor :title, :win, :draw, :lose, :player, :mission

    def self.create_map_stats(form)
      form.selected_missions.map { |mission| MapStat.create_map_stat(mission, form) }
    end

    def self.create_map_stat(mission, form)
      games = Game.joins(:game_players).
                   where(
                     mission_id:     mission.id,
                     resolutionTime: form.date_range,
                     game_players:   {
                       player_id: form.player.id
                     }
                  )
      games = games.with_opponent(form.opponent.id) if form.opponent
      MapStat.new.tap do |g|
        g.title   = mission.name
        g.player  = form.player
        g.mission = mission
        g.win     = games.where(player_id: form.player.id).count
        g.lose    = games.where.not(player_id: form.player.id).count
        g.draw    = games.where(draw: 1).count
      end
    end

    def has_games?
      total_games > 0
    end

    def total_games
      win + lose + draw
    end

    def lose_percentage
      lose / total_games.to_f * 100.0
    end
  end

end
