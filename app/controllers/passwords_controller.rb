# frozen_string_literal: true

##
# Controller for password setup and reset functionality.
# Handles password configuration for new users and password resets.
#
class PasswordsController < ApplicationController
  skip_before_action :require_login

  ##
  # Displays the password setup form for new users.
  #
  # ==== Parameters
  # * +params[:token]+ - String with password reset token
  #
  # ==== Returns
  # * Renders new view with password setup form
  # * Redirects to request_new_password_path if token is invalid or expired
  #
  # ==== Side Effects
  # * Sets @token and @user instance variables
  # * Sets flash[:alert] and redirects if token is invalid
  #
  def new
    @token = params[:token]
    @user = Usuario.find_by(password_reset_token: @token)

    if @user.nil? || token_expired?(@user)
      flash[:alert] = "Link de configuração de senha é inválido ou expirado"
      redirect_to request_new_password_path
    end
  end

  ##
  # Processes password setup submission.
  #
  # ==== Parameters
  # * +params[:token]+ - String with password reset token
  # * +params[:password]+ - String with new password
  # * +params[:password_confirmation]+ - String with password confirmation
  #
  # ==== Returns
  # * Redirects to appropriate page on success
  # * Renders new view with errors on failure
  #
  # ==== Side Effects
  # * Updates user password in database
  # * Clears password_reset_token and pending_activation
  # * Creates user session on success
  # * Sets flash messages
  #
  def create
    @user = Usuario.find_by(password_reset_token: params[:token])

    return unless validate_user_and_token
    return unless validate_password_confirmation

    update_user_password
  end

  ##
  # Validates that user exists and token is valid.
  #
  # ==== Returns
  # * Boolean - true if valid, false otherwise
  #
  # ==== Side Effects
  # * Sets flash[:alert] and redirects if invalid
  #
  def validate_user_and_token
    if @user.nil? || token_expired?(@user)
      flash[:alert] = "Link de configuração de senha é inválido ou expirado"
      redirect_to request_new_password_path
      return false
    end
    true
  end

  ##
  # Validates that password and confirmation match.
  #
  # ==== Returns
  # * Boolean - true if passwords match, false otherwise
  #
  # ==== Side Effects
  # * Sets @token instance variable
  # * Sets flash.now[:alert] and renders form if passwords don't match
  #
  def validate_password_confirmation
    if params[:password] != params[:password_confirmation]
      @token = params[:token]
      flash.now[:alert] = "A confirmação de senha não corresponde"
      render :new, status: :unprocessable_entity
      return false
    end
    true
  end

  ##
  # Updates user password attributes and saves.
  #
  # ==== Returns
  # * Redirects on success or renders error on failure
  #
  # ==== Side Effects
  # * Calls assign_new_password_attributes and save_user_password
  #
  def update_user_password
    assign_new_password_attributes
    save_user_password
  end

  ##
  # Assigns new password attributes to user object.
  #
  # ==== Side Effects
  # * Updates @user.password, pending_activation, password_reset_token, password_reset_sent_at
  #
  def assign_new_password_attributes
    @user.password = params[:password]
    @user.pending_activation = false
    @user.password_reset_token = nil
    @user.password_reset_sent_at = nil
  end

  ##
  # Saves user password and handles result.
  #
  # ==== Returns
  # * Redirects on success or renders error on failure
  #
  # ==== Side Effects
  # * Saves user to database
  # * Creates session on success
  # * Renders error form on failure
  #
  def save_user_password
    if @user.save
      login_user_after_password_set
    else
      render_password_error
    end
  end

  ##
  # Logs in user after successful password setup.
  #
  # ==== Side Effects
  # * Sets session[:user_id]
  # * Sets flash[:notice]
  # * Redirects to appropriate page based on user type
  #
  def login_user_after_password_set
    session[:user_id] = @user.id
    flash[:notice] = "Senha definida com sucesso! Você está conectado."
    redirect_to_appropriate_page(@user)
  end

  ##
  # Renders password form with error messages.
  #
  # ==== Side Effects
  # * Sets @token instance variable
  # * Sets flash.now[:alert] with error messages
  # * Renders new view with unprocessable_entity status
  #
  def render_password_error
    @token = params[:token]
    flash.now[:alert] = @user.errors.full_messages.join(", ")
    render :new, status: :unprocessable_entity
  end

  ##
  # Placeholder for requesting a new password reset link.
  #
  # ==== Returns
  # * Renders request_new view
  #
  def request_new
    # Placeholder para permitir solicitar novo link
  end

  private

  ##
  # Checks if password reset token has expired.
  #
  # ==== Parameters
  # * +user+ - Usuario object
  #
  # ==== Returns
  # * Boolean - true if token is older than 24 hours, false otherwise
  #
  def token_expired?(user)
    return false if user.password_reset_sent_at.nil?
    user.password_reset_sent_at < 24.hours.ago
  end

  ##
  # Redirects user to appropriate page based on their role.
  #
  # ==== Parameters
  # * +user+ - Usuario object
  #
  # ==== Returns
  # * Redirects to avaliacoes_path for dicentes
  # * Redirects to templates_path for docentes
  # * Redirects to root_path for other types
  #
  # ==== Side Effects
  # * Performs HTTP redirect
  #
  def redirect_to_appropriate_page(user)
    if user.dicente?
      redirect_to avaliacoes_path
    elsif user.docente?
      redirect_to templates_path
    else
      redirect_to root_path
    end
  end
end
