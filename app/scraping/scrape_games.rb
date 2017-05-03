class ScrapeGames
  require "nokogiri"
  require "httparty"

  class ScrapedMatch
    attr_accessor :id, :time, :draw, :map_name, :players
  end

  class ScrapedPlayer
    attr_accessor :name, :elo, :elo_delta, :winner
  end

  def fetch_league_latest_matches
    (2..7).map { |league|
      fetch_matches "http://gfx47.com/games/Gladiabots/Stats",
                    { league: league, display: "matches"}
    }.flatten
  end

  def fetch_user_matches(player_name)
    return [] if player_name.blank?
    fetch_matches "http://gfx47.com/games/Gladiabots/Stats/player",
                  { name: player_name, display: "matches" }
  end

  private

  def fetch_matches(url, params)
    response = HTTParty.get(url, query: params)
    parse_html Nokogiri::HTML(response), params
  end

  def parse_html(html, params)
    html.css("div.match").map do |div|
      ScrapedMatch.new.tap do |m|
        m.id       = div.css("input").first["value"].to_i
        m.time     = Time.parse div.text[/\[(.*)\]/,1]
        div        = div.css("b").first || div
        m.map_name = div.text[/\)\son\s(.*)$/,1].gsub(/\[.*\]/, "").strip
        m.draw     = div.css("span.player.draw").present?
        m.players  = div.css("span.player,span.result").map do |player|
          ScrapedPlayer.new.tap do |p|
            p.winner    = player["class"][/victory/].present?
            # Grab only text in brackets if they exist
            text        = player.text[/\((.*)\)/,1] || player.text
            p.elo       = text[/(\d+)\s((\+|\-)|0)/,1]
            p.elo_delta = text[/((\+|\-)\d+|\s0)/].to_i
            p.name = if link = player.css("a").first
                       link.text
                     else
                       params[:name]
                     end
          end
        end
      end
    end
  end

end
