# app/controllers/sigaa_imports_controller.rb
##
# Controller for importing data from SIGAA JSON files.
# Handles file uploads and database updates from SIGAA system.
#
class SigaaImportsController < ApplicationController
    before_action :require_admin
  
    ##
    # Displays the form for uploading SIGAA import files.
    #
    # ==== Returns
    # * Renders new view with import form
    #
    # ==== Side Effects
    # * None
    #
    def new
      # Renderiza formulário de importação
    end

    ##
    # Lists import history and status.
    #
    # ==== Returns
    # * Renders index view with import history
    #
    # ==== Side Effects
    # * None
    #
    def index
      # Renderiza página de listagem/histórico de importações
    end
  
  ##
  # Processes uploaded SIGAA files and imports data into the database.
  #
  # ==== Parameters
  # * +params[:classes_file]+ - UploadedFile with classes JSON data
  # * +params[:class_members_file]+ - UploadedFile with class members JSON data
  #
  # ==== Returns
  # * Redirects to sigaa_imports_path on success
  # * Renders new view with errors on failure
  #
  # ==== Side Effects
  # * Creates/updates records in database (Materia, Turma, Docente, Dicente, Matricula)
  # * Sends password setup emails to newly created users
  # * Sets flash[:notice] on success or flash[:alert] on failure
  #
  def create
    result = SigaaImporter.call(
      classes_file: params[:classes_file],
      class_members_file: params[:class_members_file],
      operation_type: 'Importação'
    )
  
      if result.success?
        flash[:notice] = result.summary_message
        redirect_to sigaa_imports_path
      else
        flash.now[:alert] = result.errors.to_sentence
        render :new, status: :unprocessable_entity
      end
    end

    ##
    # Updates database using JSON files from the repository root.
    #
    # ==== Returns
    # * Redirects to sigaa_imports_path
    #
    # ==== Side Effects
    # * Reads classes.json and class_members.json from repository root
    # * Creates/updates records in database
    # * Sets flash[:notice] on success or flash[:alert] on failure
    #
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
        class_members_file: members_file.to_s,
        operation_type: 'Atualização'
      )
      
      if result.success?
        flash[:notice] = result.summary_message
      else
        flash[:alert] = "Erro durante atualização: #{result.errors.join(', ')}"
      end
      
      redirect_to sigaa_imports_path
    end
  
    private
  
    ##
    # Requires current user to be an admin.
    #
    # ==== Returns
    # * Redirects to root_path if user is not admin
    #
    # ==== Side Effects
    # * Sets flash[:alert] with access denied message
    # * Redirects to root_path if user is not admin
    #
    def require_admin
      unless current_user&.admin?
        flash[:alert] = "Acesso negado"
        redirect_to root_path
      end
    end
  end