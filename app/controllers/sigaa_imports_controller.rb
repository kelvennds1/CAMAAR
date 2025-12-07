# app/controllers/sigaa_imports_controller.rb
class SigaaImportsController < ApplicationController
    before_action :require_admin
  
    def new
      # Renderiza formulário de importação
    end
  
    def create
      result = SigaaImporter.call(
        classes_file: params[:classes_file],
        class_members_file: params[:class_members_file]
      )
  
      if result.success?
        flash[:notice] = result.summary_message
        redirect_to sigaa_imports_path
      else
        flash.now[:alert] = result.errors.to_sentence
        render :new, status: :unprocessable_entity
      end
    end
  
    private
  
    def require_admin
      unless current_user&.admin?
        flash[:alert] = "Acesso negado"
        redirect_to root_path
      end
    end
  end