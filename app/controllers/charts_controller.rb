class ChartsController < ApplicationController

  # GET /charts/player

  def player
    @form = PlayerForm.new params[:form]
    if params[:form] && @form.valid?

      if @form.opponent.blank?
        elo_range_successes = EloRangeSuccess.create_elo_ranges(@form)
        @elo_range_chart = EloRangeSuccessChart.new(@form, elo_range_successes)
      end

      # Show elo change over time (and opponent's if selected)
      player_elos = PlayerElo.create_player_elos(player_ids: [@form.player.id, @form.opponent.try(:id)].compact,
                                                 start_date: @form.date_range.first,
                                                 end_date:   @form.date_range.last )
      @player_elo_chart = PlayerEloChart.new(player_elos)

      elo_dates = EloDate.create_elo_dates(@form)
      @elo_change_line_chart = EloChangeLineChart.new(@form, elo_dates)

      @individual_map_stats = MapStat.create_map_stats(@form)
      @stacked_map_chart    = StackedMapChart.new(@form, @individual_map_stats)
      @stacked_map_chart_elo_delta  = StackedMapChartEloDelta.new(@form, @individual_map_stats)
      @lost_and_drawn_games = Game.lost_or_drawn(@form.player.id, @form.opponent.try(:id)).
                                   where(mission_id: @form.selected_missions.map(&:id)).
                                   where(resolution_time: @form.date_range).
                                   by_resolution_time
      # Create 'Top X played against' and 'Top X Elo Delta' charts
      player_stats  = PlayerStat.create_player_stats(@form)
      @stacked_players_chart = StackedPlayerGamesChart.new(@form, player_stats)
      @elo_delta_chart = StackedPlayerEloDeltaChart.new(@form, player_stats, number_of_players: 50)
    end
  end

  # GET /charts/global

  def global
    player_elos = PlayerElo.create_player_elos
    @player_elo_chart = PlayerEloChart.new(player_elos)
  end

  private

  # TODO: move these classes somewhere sensible...
 
  class PlayerForm
    include ActiveModel::Model
    include Virtus.model

    attribute :player_name
    attribute :opponent_player_name # optional
    attribute :start_date,  Date, default: ->(form, attribute) { Time.now - 5.days }
    attribute :end_date,    Date, default: ->(form, attribute) { Time.now }
    attribute :mission_ids, Array[Integer]

    validates :player_name, :start_date, :end_date, presence: true
    validate  :check_players_names
    validate  :check_dates

    def player
      @pl ||= Player.with_name(player_name.strip)
    end

    def opponent
      @op ||= Player.with_name(opponent_player_name.strip) if opponent_player_name.present?
    end

    def date_range
      start_date.at_beginning_of_day..end_date.end_of_day
    end

    def selected_missions
      @sm ||= mission_ids.blank? ? Mission.all : Mission.find(mission_ids)
    end

    def available_missions
      @am ||= Mission.active
    end

    private

    def check_players_names
      errors.add(:player_name, similar_name_message(player_name)) if player.blank?
      errors.add(:opponent_player_name, similar_name_message(opponent_player_name)) if opponent_player_name.present? &&
                                                                                       opponent.blank?
    end

    def check_dates
      errors.add(:start_date, "is not a valid date") unless start_date.is_a?(Date)
      errors.add(:end_date, "is not a valid date") unless end_date.is_a?(Date)
      errors.add(:end_date, "is before the end date") if start_date.is_a?(Date) && end_date.is_a?(Date) && end_date < start_date
    end

    def similar_name_message(name)
      message = "does not exist."
      if name.present?
        similar_players = Player.similar_to(name).limit(50).by_name.to_a || Player.similar_to(name.split.first).by_name.limit(50).to_a
        if similar_players.any?
          message << " These similar players exist: "
          message << similar_players.map(&:name).join(", ")
        end
      end
      message
    end
  end

  class PlayerEloChart

    def initialize(player_elos)
      @player_elos = player_elos.sort_by { |pe|
        pe.elos.last.elo_delta
      }.reverse
    end

    def title
      "Historical Player Elo"
    end

    def y_axis_title
      "Elo"
    end

    def categories
      @player_elos.map(&:player).map(&:name)
    end

    def series
        @player_elos.map do |player_elo|
          [ player_elo.player.name,  player_elo.elos ]
        end
    end
  end

  class PlayerElo

    attr_accessor :player, :elos

    class Elo
      attr_accessor :date,
                    :position,
                    :elo_delta
    end

    def self.create_player_elos(player_ids: nil, start_date: Time.now - 3.weeks, end_date: Time.now)
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
        with_max_id.no_of_games > 2
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
          start_time: start_date, end_time: end_date,
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

  class EloRangeSuccessChart

    def initialize(form, elo_range_successes)
      @form = form
      @elo_range_successes = elo_range_successes
    end

    def title
      "Success against Elo Ranges"
    end

    def y_axis_title
      "%"
    end

    def categories
      @elo_range_successes.map(&:elo_range)
    end

    def series
      [
        ["Win", @elo_range_successes.map(&:win_percentage)],
        ["Lose", @elo_range_successes.map(&:lost_percentage)],
        ["Draw", @elo_range_successes.map(&:draw_percentage)]
      ]
    end
  end

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

  class EloChangeLineChart

    def initialize(form, elo_dates)
      @form = form
      @elo_dates = elo_dates.sort_by(&:date)
    end

    def title
      @form.opponent ? "Daily Elo Delta against #{@form.opponent.name}" : "Daily Elo Delta" 
    end

    def y_axis_title
      "Elo Delta"
    end

    def series
      [
        ["Elo Delta", @elo_dates ]
      ]
    end
  end

  class StackedMapChart
    def initialize(form, map_stats)
      @form = form
      @map_stats  = map_stats.sort_by(&:lose_percentage)
      @missions   = @map_stats.map(&:mission)
    end

    def title
      @form.opponent ? "#{@form.player.name} against #{@form.opponent.name}" : "All Maps"
    end

    def categories
      @missions.map(&:name)
    end

    def y_axis_title
      "Number of Games"
    end

    def series
      [
        [ "Draw", @missions.map { |m| @map_stats.find{ |ms| ms.mission == m }.draw } ],
        [ "Lose", @missions.map { |m| @map_stats.find{ |ms| ms.mission == m }.lose } ],
        [ "Win",  @missions.map { |m| @map_stats.find{ |ms| ms.mission == m }.win  } ]
      ]
    end
  end

  class StackedMapChartEloDelta

    def initialize(form, map_stats)
      @form = form
      @map_stats  = map_stats.sort_by(&:lose_percentage)
      @missions   = @map_stats.map(&:mission)
    end

    def title
      "Elo Delta for " + (@form.opponent ? "#{@form.player.name} against #{@form.opponent.name}" : "All Maps")
    end

    def categories
      ["Total"] + @missions.map(&:name)
    end

    def y_axis_title
      "Elo"
    end

    def series
      total_elo_delta = @map_stats.sum(&:elo_delta)
      [
        [ "Elo Delta", [total_elo_delta] + @missions.map { |m| @map_stats.find{ |ms| ms.mission == m }.elo_delta } ]
      ]
    end
  end


  class StackedPlayerGamesChart

    def initialize(form, player_stats, number_of_players: 50)
      @form = form
      @number_of_players = number_of_players
      @stats = player_stats.sort_by(&:total_games).
                            reverse[0..(@number_of_players - 1)]
      @opponents = @stats.map(&:opponent)
    end

    def title
      "Top #{@number_of_players} #{@form.player.name} Played Against"
    end

    def categories
      @opponents.map(&:name)
    end

    def y_axis_title
      "Number of Games"
    end

    def series
      [
        [ "Draw", @opponents.map { |o| @stats.find{ |ms| ms.opponent.id == o.id }.draw } ],
        [ "Lose", @opponents.map { |o| @stats.find{ |ms| ms.opponent.id == o.id }.lose } ],
        [ "Win",  @opponents.map { |o| @stats.find{ |ms| ms.opponent.id == o.id }.win  } ]
      ]
    end
  end

  class StackedPlayerEloDeltaChart

    def initialize(form, player_stats, number_of_players: 30)
      @number_of_players = number_of_players
      @form = form
      @stats = player_stats.partition{ |ps| ps.elo_delta < 0 }.
                            map{ |stats| stats.sort_by{ |ps| ps.elo_delta.abs }.reverse[0..(@number_of_players/2-1)] }.
                            inject(&:+)
      @opponents = @stats.map(&:opponent)
    end

    def title
      "Top #{@number_of_players} #{@form.player.name} Elo Delta"
    end

    def categories
      @opponents.map(&:name)
    end

    def y_axis_title
      "Elo"
    end

    def series
      [
        [ "Elo Delta",  @opponents.map { |o| @stats.find{ |ms| ms.opponent.id == o.id }.elo_delta  } ]
      ]
    end
  end

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

  class PlayerStat
    attr_accessor :player,
                  :opponent,
                  :missions,
                  :win, :draw, :lose,
                  :elo_delta

    def self.create_player_stats(form)
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
          player_id:   form.player.id,
          mission_ids: form.selected_missions.map(&:id),
          start_date:  form.date_range.first, end_date: form.date_range.last
        }
      ]
      Game.find_by_sql(sql).map do |row|
        PlayerStat.new.tap do |g|
          g.player   = form.player
          g.opponent = Player.new(id: row.opponent_id, name: row.opponent_name)
          g.missions = form.selected_missions
          g.win      = row.win
          g.lose     = row.lose
          g.draw     = row.draw
          g.elo_delta= row.elo_delta
        end
      end
    end

    def total_games
      win + lose + draw
    end
  end

end
