# frozen_string_literal: true

##
# Controller for managing user sessions (login/logout).
# Handles authentication and session management.
#
class SessionsController < ApplicationController
  skip_before_action :require_login, only: [:new, :create]

  ##
  # Displays the login form.
  #
  # ==== Returns
  # * Renders new view with login form
  # * Redirects to appropriate page if already logged in
  #
  # ==== Side Effects
  # * Redirects to appropriate page based on user type if already logged in
  #
  def new
    # Redirect se já estiver logado
    if logged_in?
      redirect_to_appropriate_page(current_user)
    end
  end

  ##
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
  #
  def create
    user = Usuario.find_by(email: params[:email])

    if user && user.authenticate(params[:password])
      if user.respond_to?(:pending_activation) && user.pending_activation
        flash[:alert] = "Por favor, ative sua conta primeiro"
        redirect_to login_path
      else
        session[:user_id] = user.id
        redirect_to_appropriate_page(user)
      end
    else
      flash.now[:alert] = "Invalid email or password"
      render :new, status: :unprocessable_entity
    end
  end

  ##
  # Destroys the current session and logs out the user.
  #
  # ==== Returns
  # * Redirects to login_path with success notice
  #
  # ==== Side Effects
  # * Clears session[:user_id]
  # * Sets flash[:notice] with logout confirmation message
  #
  def destroy
    session[:user_id] = nil
    redirect_to login_path, notice: "Sessão encerrada com sucesso"
  end

  private

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
