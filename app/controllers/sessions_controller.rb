# frozen_string_literal: true

##
<<<<<<< HEAD
# Controller for handling user authentication sessions.
# Manages login, logout, and session management.
=======
# Controller for managing user sessions (login/logout).
# Handles authentication and session management.
>>>>>>> sprint-3-documentacao
#
class SessionsController < ApplicationController
  skip_before_action :require_login, only: [:new, :create]

  ##
  # Displays the login form.
<<<<<<< HEAD
  # Redirects to appropriate page if already logged in.
=======
  #
  # ==== Returns
  # * Renders new view with login form
  # * Redirects to appropriate page if already logged in
  #
  # ==== Side Effects
  # * Redirects to appropriate page based on user type if already logged in
>>>>>>> sprint-3-documentacao
  #
  def new
    redirect_to_appropriate_page(current_user) if logged_in?
  end

  ##
<<<<<<< HEAD
  # Authenticates user and creates session.
  #
  # ==== Parameters
  # * +email+ - User email (from params)
  # * +password+ - User password (from params)
  #
  # ==== Returns
  # * Redirects to appropriate page on success
  # * Renders login form with error on failure
=======
  # Authenticates user and creates a session.
  #
  # ==== Parameters
  # * +params[:email]+ - String with user email
  # * +params[:password]+ - String with user password
  #
  # ==== Returns
  # * Redirects to appropriate page on success
  # * Renders new view with error on failure
  #
  # ==== Side Effects
  # * Sets session[:user_id] on successful authentication
  # * Sets flash[:alert] on failure or if account is pending activation
  # * Redirects to login_path if account is pending activation
>>>>>>> sprint-3-documentacao
  #
  def create
    user = find_user_by_email

    return render_invalid_credentials unless user&.authenticate(params[:password])
    return render_pending_activation if pending_activation?(user)

    login_user(user)
  end

  ##
<<<<<<< HEAD
  # Destroys user session (logout).
  #
  # ==== Side Effects
  # * Clears session[:user_id]
  # * Redirects to login page
=======
  # Destroys the current session and logs out the user.
  #
  # ==== Returns
  # * Redirects to login_path with success notice
  #
  # ==== Side Effects
  # * Clears session[:user_id]
  # * Sets flash[:notice] with logout confirmation message
>>>>>>> sprint-3-documentacao
  #
  def destroy
    session[:user_id] = nil
    redirect_to login_path, notice: "Sessão encerrada com sucesso"
  end

  private

<<<<<<< HEAD
  def find_user_by_email
    Usuario.find_by(email: params[:email])
  end

  def pending_activation?(user)
    user.respond_to?(:pending_activation) && user.pending_activation
  end

  def render_invalid_credentials
    flash.now[:alert] = "Invalid email or password"
    render :new, status: :unprocessable_entity
  end

  def render_pending_activation
    flash[:alert] = "Por favor, ative sua conta primeiro"
    redirect_to login_path
  end

  def login_user(user)
    session[:user_id] = user.id
    redirect_to_appropriate_page(user)
  end

=======
  ##
  # Redirects user to the appropriate page based on their role.
  #
  # ==== Parameters
  # * +user+ - Usuario object (can be Dicente or Docente)
  #
  # ==== Returns
  # * Redirects to formularios_pendentes_path for dicentes
  # * Redirects to templates_path for docentes
  # * Redirects to root_path for other user types
  #
  # ==== Side Effects
  # * Performs HTTP redirect
  #
>>>>>>> sprint-3-documentacao
  def redirect_to_appropriate_page(user)
    if user.dicente?
      redirect_to formularios_pendentes_path
    elsif user.docente?
      redirect_to templates_path
    else
      redirect_to root_path
    end
  end
end
