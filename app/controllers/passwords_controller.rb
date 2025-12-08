# frozen_string_literal: true

class PasswordsController < ApplicationController
  skip_before_action :require_login

  def new
    @token = params[:token]
    @user = Usuario.find_by(password_reset_token: @token)

    if @user.nil? || token_expired?(@user)
      flash[:alert] = "Link de configuração de senha é inválido ou expirado"
      redirect_to request_new_password_path
    end
  end

  def create
    @user = Usuario.find_by(password_reset_token: params[:token])

    if @user.nil? || token_expired?(@user)
      flash[:alert] = "Link de configuração de senha é inválido ou expirado"
      redirect_to request_new_password_path
      return
    end

    if params[:password] != params[:password_confirmation]
      @token = params[:token]
      flash.now[:alert] = "A confirmação de senha não corresponde"
      render :new, status: :unprocessable_entity
      return
    end

    @user.password = params[:password]
    @user.pending_activation = false
    @user.password_reset_token = nil
    @user.password_reset_sent_at = nil

    if @user.save
      session[:user_id] = @user.id
      flash[:notice] = "Senha definida com sucesso! Você está conectado."
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
