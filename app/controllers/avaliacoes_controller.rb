require "ostruct"

##
# Controller for managing evaluations (Avaliacoes).
# Handles listing pending evaluations, creating evaluation batches,
# and submitting student responses.
#
class AvaliacoesController < ApplicationController
  before_action :load_collections, only: %i[index create]
  before_action :build_form_object, only: :index

  ##
  # Lists all evaluations (admin view).
  #
  # ==== Returns
  # * Renders index view with evaluation form and list
  #
  def index; end

  ##
  # Lists pending evaluations for the current student.
  #
  # ==== Returns
  # * Renders pendentes view with list of pending evaluations for the current dicente
  #
  def pendentes
    if current_user&.dicente?
      @avaliacoes_pendentes = Avaliacao.pending_for_dicente(current_user)
                                        .includes(:turma, :docente, :template, turma: :materia)
                                        .order("avaliacoes.due_date ASC")
                                        .distinct
    else
      @avaliacoes_pendentes = []
    end
  end

  def responder
    @avaliacao = Avaliacao.find(params[:id])
    
    unless current_user.dicente?
      flash[:alert] = "Você não tem permissão para responder este formulário"
      redirect_to formularios_pendentes_path
      return
    end

    # Verificar se o dicente está matriculado na turma
    unless current_user.turmas.include?(@avaliacao.turma)
      flash[:alert] = "Você não tem permissão para responder este formulário"
      redirect_to formularios_pendentes_path
      return
    end

    # Verificar se já respondeu
    @resposta_existente = Resposta.find_by(avaliacao: @avaliacao, dicente: current_user)
    if @resposta_existente&.submitted?
      flash[:alert] = "Você já respondeu este formulário"
      redirect_to formularios_pendentes_path
      return
    end

    # Carregar questões ordenadas
    @questoes = @avaliacao.questoes.order(:position)
    
    # Criar ou carregar resposta pendente
    @resposta = @resposta_existente || Resposta.new(avaliacao: @avaliacao, dicente: current_user, status: :pending)
  end

  ##
  # Submits a student's response to an evaluation.
  #
  # ==== Parameters
  # * +id+ - Avaliacao ID (from params)
  # * +respostas+ - Hash of responses indexed by questao_id (from params)
  #
  # ==== Returns
  # * Redirects to pendentes path on success
  # * Renders responder form with errors on failure
  #
  # ==== Side Effects
  # * Creates or updates Resposta record
  # * Creates RespostaItem records for each question
  # * Validates mandatory questions are answered
  #
  def submeter
    @avaliacao = Avaliacao.find(params[:id])

    return unless validate_submission_permissions
    return unless validate_not_already_submitted

    @resposta = find_or_initialize_resposta
    submit_resposta
  end

  def validate_submission_permissions
    unless current_user.dicente?
      flash[:alert] = "Você não tem permissão para responder este formulário"
      redirect_to formularios_pendentes_path
      return false
    end

    unless current_user.turmas.include?(@avaliacao.turma)
      flash[:alert] = "Você não tem permissão para responder este formulário"
      redirect_to formularios_pendentes_path
      return false
    end

    true
  end

  def validate_not_already_submitted
    resposta_existente = Resposta.find_by(avaliacao: @avaliacao, dicente: current_user)

    if resposta_existente&.submitted?
      flash[:alert] = "Você já respondeu este formulário"
      redirect_to formularios_pendentes_path
      return false
    end

    @resposta_existente = resposta_existente
    true
  end

  def find_or_initialize_resposta
    @resposta_existente || Resposta.new(avaliacao: @avaliacao, dicente: current_user)
  end

  def submit_resposta
    if processar_respostas(@resposta)
      save_submitted_resposta
    else
      render_submission_error
    end
  end

  def save_submitted_resposta
    @resposta.status = :submitted
    @resposta.submitted_at = Time.current

    if @resposta.save
      flash[:notice] = "Avaliação enviada com sucesso!"
      redirect_to formularios_pendentes_path
    else
      render_submission_error
    end
  end

  def render_submission_error
    @questoes = @avaliacao.questoes.order(:position)
    error_message = @resposta.errors.full_messages.to_sentence.presence ||
                    "Erro ao enviar o formulário. Verifique se todas as perguntas obrigatórias foram respondidas."
    flash.now[:alert] = error_message
    render :responder, status: :unprocessable_entity
  end

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

  def processar_respostas(resposta)
    return false unless params[:respostas].present?
    return false unless validate_mandatory_questions(resposta)

    save_all_resposta_items(resposta)
  end

  def validate_mandatory_questions(resposta)
    questoes_obrigatorias = @avaliacao.questoes.where(mandatory: true)

    questoes_obrigatorias.each do |questao|
      valor = params[:respostas][questao.id.to_s]
      if valor.blank?
        resposta.errors.add(:base, "A pergunta '#{questao.prompt}' é obrigatória")
        return false
      end
    end

    true
  end

  def save_all_resposta_items(resposta)
    params[:respostas].each do |questao_id, valor|
      questao = Questao.find_by(id: questao_id)
      next unless valid_questao_for_avaliacao?(questao)
      next if skip_blank_optional_questao?(questao, valor)

      return false unless save_resposta_item(resposta, questao, valor)
    end

    true
  end

  def valid_questao_for_avaliacao?(questao)
    questao && questao.avaliacao == @avaliacao
  end

  def skip_blank_optional_questao?(questao, valor)
    valor.blank? && !questao.mandatory
  end

  def save_resposta_item(resposta, questao, valor)
    resposta_item = resposta.resposta_items.find_or_initialize_by(questao: questao)
    resposta_item.valor = valor.to_s

    unless resposta_item.save
      resposta.errors.add(:base, "Erro ao salvar resposta para '#{questao.prompt}'")
      return false
    end

    true
  end
end
