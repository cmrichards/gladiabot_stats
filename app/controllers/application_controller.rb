class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  helper_method :current_player_name, :current_player

  def current_player_name
    session[:current_player_name]
  end

  def current_player
    return if current_player_name.blank?
    @current_player ||= Player.with_name(session[:current_player_name])
  end
end
