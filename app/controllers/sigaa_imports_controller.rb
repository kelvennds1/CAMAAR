# app/controllers/sigaa_imports_controller.rb
class SigaaImportsController < ApplicationController
    before_action :require_admin
  
    def new
      # Renderiza formulário de importação
    end

    def index
      # Renderiza página de listagem/histórico de importações
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

    def update_database
      # Caminhos dos arquivos JSON no repositório
      classes_file = Rails.root.join('classes.json')
      members_file = Rails.root.join('class_members.json')
      
      # Verificar se os arquivos existem
      unless File.exist?(classes_file) && File.exist?(members_file)
        flash[:alert] = "Arquivos JSON não encontrados no repositório. Certifique-se de que classes.json e class_members.json estão na raiz do projeto."
        redirect_to sigaa_imports_path
        return
      end
      
      # Executar a atualização
      result = SigaaImporter.call(
        classes_file: classes_file.to_s,
        class_members_file: members_file.to_s
      )
      
      if result.success?
        flash[:notice] = result.summary_message
      else
        flash[:alert] = "Erro durante atualização: #{result.errors.join(', ')}"
      end
      
      redirect_to sigaa_imports_path
    end
  
    private
  
    def require_admin
      unless current_user&.admin?
        flash[:alert] = "Acesso negado"
        redirect_to root_path
      end
    end
  end