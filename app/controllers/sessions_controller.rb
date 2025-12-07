# frozen_string_literal: true

class SessionsController < ApplicationController
  skip_before_action :require_login, only: [:new, :create]

  def new
    # Renderiza a página de login
  end

  def create
    user = Usuario.find_by(email: params[:email])

    if user && user.authenticate(params[:password])
      if user.respond_to?(:pending_activation) && user.pending_activation
        flash[:alert] = "Please activate your account first"
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
    redirect_to login_path, notice: "Logged out successfully"
  end

  private

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
