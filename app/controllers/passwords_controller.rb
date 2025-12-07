# frozen_string_literal: true

class PasswordsController < ApplicationController
  skip_before_action :require_login

  def new
    @token = params[:token]
    @user = Usuario.find_by(password_reset_token: @token)

    if @user.nil? || token_expired?(@user)
      flash[:alert] = "Password setup link is invalid or expired"
      redirect_to request_new_password_path
    end
  end

  def create
    @user = Usuario.find_by(password_reset_token: params[:token])

    if @user.nil? || token_expired?(@user)
      flash[:alert] = "Password setup link is invalid or expired"
      redirect_to request_new_password_path
      return
    end

    if params[:password] != params[:password_confirmation]
      @token = params[:token]
      flash.now[:alert] = "Password confirmation doesn't match"
      render :new, status: :unprocessable_entity
      return
    end

    if @user.update(password: params[:password], password_reset_token: nil, password_reset_sent_at: nil, pending_activation: false)
      session[:user_id] = @user.id
      flash[:notice] = "Password set successfully! You are now logged in."
      redirect_to_appropriate_page(@user)
    else
      @token = params[:token]
      flash.now[:alert] = @user.errors.full_messages.join(", ")
      render :new, status: :unprocessable_entity
    end
  end

  def request_new
    # Placeholder para permitir solicitar novo link
  end

  private

  def token_expired?(user)
    return false if user.password_reset_sent_at.nil?
    user.password_reset_sent_at < 24.hours.ago
  end

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
