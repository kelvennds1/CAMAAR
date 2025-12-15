##
# Base controller for all application controllers.
# Provides authentication and user session management functionality.
#
class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  before_action :require_login

  helper_method :current_user, :logged_in?

  private

  ##
  # Returns the currently logged in user.
  #
  # ==== Returns
  # * Usuario - The current user object if logged in, nil otherwise
  #
  # ==== Side Effects
  # * None - This is a read-only method that caches the result in @current_user
  #
  def current_user
    @current_user ||= Usuario.find_by(id: session[:user_id]) if session[:user_id]
  end

  ##
  # Checks if a user is currently logged in.
  #
  # ==== Returns
  # * Boolean - true if a user is logged in, false otherwise
  #
  # ==== Side Effects
  # * None
  #
  def logged_in?
    current_user.present?
  end

  ##
  # Requires user to be logged in before accessing controller actions.
  # Redirects to login page if user is not authenticated.
  #
  # ==== Returns
  # * Redirects to login_path if not logged in
  #
  # ==== Side Effects
  # * Sets flash[:alert] with error message
  # * Redirects to login_path if user is not logged in
  #
  def require_login
    unless logged_in?
      flash[:alert] = "Por favor, faça login para continuar"
      redirect_to login_path
    end
  end
end
