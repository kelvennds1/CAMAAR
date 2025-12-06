require "ostruct"

class AvaliacoesController < ApplicationController
  before_action :load_collections, only: %i[index create]
  before_action :build_form_object, only: :index

  def index; end

  def create
    @avaliacao_batch = OpenStruct.new(batch_params.to_h)
    result = EvaluationBatchCreator.call(**batch_params.to_h.symbolize_keys)

    if result.success?
      flash[:notice] = success_message(result)
      redirect_to avaliacoes_path
    else
      flash.now[:alert] = result.errors.to_sentence
      render :index, status: :unprocessable_entity
    end
  end

  private

  def batch_params
    params.require(:avaliacao_batch).permit(:template_id, :due_date, turma_ids: [])
  rescue ActionController::ParameterMissing
    { template_id: nil, due_date: nil, turma_ids: [] }
  end

  def load_collections
    @current_semester = current_semester
    @templates = Template.includes(:docente).order(:name)
    @turmas = Turma.includes(:materia, :docente).where(semester: @current_semester).order(:class_code)
    @avaliacoes = Avaliacao.includes(:turma, :docente, :template).order(created_at: :desc)
  end

  def build_form_object
    @avaliacao_batch = OpenStruct.new(template_id: nil, due_date: default_due_date)
  end

  def default_due_date
    Time.zone.today.end_of_month
  end

  def current_semester
    date = Time.zone.today
    term = date.month <= 6 ? 1 : 2
    format('%<year>d.%<term>d', year: date.year, term: term)
  end

  def success_message(result)
    created = result.created.size
    skipped = result.skipped.size
    "#{created} formulário(s) criado(s) e #{skipped} turma(s) ignoradas por já possuírem o formulário."
  end
end
