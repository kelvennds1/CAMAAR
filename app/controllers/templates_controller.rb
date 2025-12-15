class TemplatesController < ApplicationController
  before_action :set_current_admin_id
  before_action :set_template, only: %i[edit update destroy]
  before_action :ensure_template_owner!, only: %i[edit update destroy]
  before_action :load_dependencies, only: %i[index edit]

  def index
    @template = Template.new(status: Template::STATUS[:draft])
    build_placeholder_question
  end

  def edit
    build_placeholder_question
    render :index
  end

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

  def destroy
    @template.destroy!
    @current_admin_id ||= @template.docente_id
    redirect_to templates_redirect_path, notice: "Template removido com sucesso."
  rescue StandardError
    redirect_to templates_redirect_path,
                alert: "Não foi possível remover o template. Tente novamente mais tarde."
  end

  private

  def template_params
    params.require(:template).permit(
      :name,
      :description,
      :docente_id,
      template_questions_attributes: %i[id prompt question_type position required min_value max_value options_text _destroy]
    )
  end

  def load_dependencies
    @docentes = Docente.order(:nome)
    scope = Template.includes(:template_questions, :docente).order(created_at: :desc)
    scope = scope.where(docente_id: @current_admin_id) if @current_admin_id
    @templates = scope
  end

  def set_current_admin_id
    @current_admin_id = params[:admin_id].presence
  end

  def set_template
    @template = Template.includes(:template_questions).find(params[:id])
    @current_admin_id ||= @template.docente_id
  end

  def ensure_template_owner!
    return unless @current_admin_id

    return if @template.docente_id.to_s == @current_admin_id.to_s

    redirect_to templates_redirect_path, alert: "Template não encontrado para este administrador."
  end

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
    [active_count, base_slots].max - active_count
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
