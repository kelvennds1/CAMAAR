##
# Controller for managing evaluation templates.
# Handles CRUD operations for templates and their associated questions.
#
class TemplatesController < ApplicationController
  before_action :set_current_admin_id
  before_action :set_template, only: %i[edit update destroy]
  before_action :ensure_template_owner!, only: %i[edit update destroy]
  before_action :load_dependencies, only: %i[index edit]

  ##
  # Lists all templates and displays form for creating new template.
  #
  # ==== Returns
  # * Renders index view with templates list and new template form
  #
  # ==== Side Effects
  # * Sets @template, @docentes, @templates instance variables
  #
  def index
    @template = Template.new(status: Template::STATUS[:draft])
    build_placeholder_question
  end

  ##
  # Displays form for editing an existing template.
  #
  # ==== Parameters
  # * +params[:id]+ - Integer with Template ID
  #
  # ==== Returns
  # * Renders index view with edit form
  #
  # ==== Side Effects
  # * Sets @template instance variable
  #
  def edit
    build_placeholder_question
    render :index
  end

  ##
  # Creates a new template.
  #
  # ==== Parameters
  # * +params[:template]+ - Hash with template attributes (name, description, docente_id, template_questions_attributes)
  #
  # ==== Returns
  # * Redirects to templates_redirect_path on success
  # * Renders index view with errors on failure
  #
  # ==== Side Effects
  # * Creates Template record in database
  # * Creates TemplateQuestion records in database
  # * Sets flash[:notice] on success or flash[:alert] on failure
  #
  def create
    @template = Template.new(template_params)

    if @template.save
      @current_admin_id ||= @template.docente_id
      redirect_to templates_redirect_path, notice: "Template criado com sucesso."
    else
      load_dependencies
      build_placeholder_question
      flash.now[:alert] = "Não foi possível salvar o template. Corrija os campos destacados."
      render :index, status: :unprocessable_entity
    end
  end

  ##
  # Updates an existing template.
  #
  # ==== Parameters
  # * +params[:id]+ - Integer with Template ID
  # * +params[:template]+ - Hash with template attributes
  #
  # ==== Returns
  # * Redirects to templates_redirect_path on success
  # * Renders index view with errors on failure
  #
  # ==== Side Effects
  # * Updates Template record in database
  # * Updates or destroys TemplateQuestion records
  # * Sets flash[:notice] on success or flash[:alert] on failure
  #
  def update
    if @template.update(template_params)
      @current_admin_id ||= @template.docente_id
      redirect_to templates_redirect_path, notice: "Template atualizado com sucesso."
    else
      load_dependencies
      build_placeholder_question
      flash.now[:alert] = "Não foi possível atualizar o template. Corrija os campos destacados."
      render :index, status: :unprocessable_entity
    end
  end

  ##
  # Deletes a template.
  #
  # ==== Parameters
  # * +params[:id]+ - Integer with Template ID
  #
  # ==== Returns
  # * Redirects to templates_redirect_path
  #
  # ==== Side Effects
  # * Destroys Template record from database
  # * Sets flash[:notice] on success or flash[:alert] on failure
  #
  def destroy
    @template.destroy!
    @current_admin_id ||= @template.docente_id
    redirect_to templates_redirect_path, notice: "Template removido com sucesso."
  rescue StandardError
    redirect_to templates_redirect_path,
                alert: "Não foi possível remover o template. Tente novamente mais tarde."
  end

  private

  ##
  # Extracts and sanitizes template parameters.
  #
  # ==== Returns
  # * ActionController::Parameters - Permitted template parameters
  #
  def template_params
    params.require(:template).permit(
      :name,
      :description,
      :docente_id,
      template_questions_attributes: %i[id prompt question_type position required min_value max_value options_text _destroy]
    )
  end

  ##
  # Loads dependencies needed for index and edit views.
  #
  # ==== Side Effects
  # * Sets @docentes and @templates instance variables
  #
  def load_dependencies
    @docentes = Docente.order(:nome)
    scope = Template.includes(:template_questions, :docente).order(created_at: :desc)
    scope = scope.where(docente_id: @current_admin_id) if @current_admin_id
    @templates = scope
  end

  ##
  # Sets the current admin ID from parameters.
  #
  # ==== Side Effects
  # * Sets @current_admin_id instance variable
  #
  def set_current_admin_id
    @current_admin_id = params[:admin_id].presence
  end

  ##
  # Loads template from database.
  #
  # ==== Parameters
  # * +params[:id]+ - Integer with Template ID
  #
  # ==== Side Effects
  # * Sets @template and @current_admin_id instance variables
  #
  def set_template
    @template = Template.includes(:template_questions).find(params[:id])
    @current_admin_id ||= @template.docente_id
  end

  ##
  # Ensures current user owns the template being accessed.
  #
  # ==== Returns
  # * Redirects to templates_redirect_path if user doesn't own template
  #
  # ==== Side Effects
  # * Sets flash[:alert] and redirects if access denied
  #
  def ensure_template_owner!
    return unless @current_admin_id

    return if @template.docente_id.to_s == @current_admin_id.to_s

    redirect_to templates_redirect_path, alert: "Template não encontrado para este administrador."
  end

  ##
  # Determines redirect path based on admin context.
  #
  # ==== Returns
  # * String - Path to redirect to (management_templates_path or templates_path)
  #
  def templates_redirect_path
    if @current_admin_id
      management_templates_path(admin_id: @current_admin_id)
    else
      templates_path
    end
  end

  ##
  # Builds placeholder questions for the template form.
  # Ensures minimum number of question slots are available.
  #
  # ==== Side Effects
  # * Adds TemplateQuestion objects to @template.template_questions
  #
  def build_placeholder_question
    slots_needed = calculate_slots_needed
    add_placeholder_questions(slots_needed)
  end

  ##
  # Calculates how many question slots are needed.
  #
  def calculate_slots_needed
    base_slots = @template.persisted? ? 1 : 3
    active_count = count_active_questions
    [ active_count, base_slots ].max - active_count
  end

  ##
  # Counts non-destroyed questions.
  #
  def count_active_questions
    @template.template_questions.reject(&:marked_for_destruction?).size
  end

  ##
  # Adds the specified number of placeholder questions.
  #
  def add_placeholder_questions(count)
    count.times { build_single_placeholder_question }
  end

  ##
  # Builds a single placeholder question with default values.
  #
  def build_single_placeholder_question
    @template.template_questions.build(
      question_type: TemplateQuestion::QUESTION_TYPES[:likert],
      position: @template.template_questions.size + 1,
      required: true,
      min_value: 1,
      max_value: 5
    )
  end
end
