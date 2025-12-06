class TemplatesController < ApplicationController
  before_action :load_dependencies, only: :index

  def index
    @template = Template.new(status: Template::STATUS[:draft])
    build_placeholder_question
  end

  def create
    @template = Template.new(template_params)

    if @template.save
      redirect_to templates_path, notice: "Template criado com sucesso."
    else
      load_dependencies
      build_placeholder_question
      flash.now[:alert] = "Não foi possível salvar o template. Corrija os campos destacados."
      render :index, status: :unprocessable_entity
    end
  end

  private

  def template_params
    params.require(:template).permit(
      :name,
      :description,
      :docente_id,
      template_questions_attributes: %i[id prompt question_type position required min_value max_value options_text _destroy]
    ).merge(status: Template::STATUS[:draft])
  end

  def load_dependencies
    @docentes = Docente.order(:nome)
    @current_admin_id = params[:admin_id].presence
    scope = Template.includes(:template_questions, :docente).order(created_at: :desc)
    scope = scope.where(docente_id: @current_admin_id) if @current_admin_id
    @templates = scope
  end

  def build_placeholder_question
    base_slots = @template.persisted? ? 1 : 3
    active_questions = @template.template_questions.reject(&:marked_for_destruction?).size
    total_needed = [active_questions, base_slots].max

    while active_questions < total_needed
      @template.template_questions.build(
        question_type: TemplateQuestion::QUESTION_TYPES[:likert],
        position: @template.template_questions.size + 1,
        required: true,
        min_value: 1,
        max_value: 5
      )
      active_questions += 1
    end
  end
end
