# frozen_string_literal: true

class SessionsController < ApplicationController
  skip_before_action :require_login, only: [:new, :create]

  def new
    # Redirect se já estiver logado
    if logged_in?
      redirect_to_appropriate_page(current_user)
    end
  end

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

  def destroy
    session[:user_id] = nil
    redirect_to login_path, notice: "Sessão encerrada com sucesso"
  end

  private

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
