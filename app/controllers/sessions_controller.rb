# frozen_string_literal: true

##
# Controller for handling user authentication sessions.
# Manages login, logout, and session management.
#
class SessionsController < ApplicationController
  skip_before_action :require_login, only: [:new, :create]

  ##
  # Displays the login form.
  # Redirects to appropriate page if already logged in.
  #
  def new
    redirect_to_appropriate_page(current_user) if logged_in?
  end

  ##
  # Authenticates user and creates session.
  #
  # ==== Parameters
  # * +email+ - User email (from params)
  # * +password+ - User password (from params)
  #
  # ==== Returns
  # * Redirects to appropriate page on success
  # * Renders login form with error on failure
  #
  def create
    user = find_user_by_email

    return render_invalid_credentials unless user&.authenticate(params[:password])
    return render_pending_activation if pending_activation?(user)

    login_user(user)
  end

  ##
  # Destroys user session (logout).
  #
  # ==== Side Effects
  # * Clears session[:user_id]
  # * Redirects to login page
  #
  def destroy
    session[:user_id] = nil
    redirect_to login_path, notice: "Sessão encerrada com sucesso"
  end

  private

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
