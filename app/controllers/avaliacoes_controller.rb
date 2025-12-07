require "ostruct"

class AvaliacoesController < ApplicationController
  before_action :load_collections, only: %i[index create]
  before_action :build_form_object, only: :index

  def index; end

  def pendentes
    if current_user.dicente?
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

  def submeter
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
    resposta_existente = Resposta.find_by(avaliacao: @avaliacao, dicente: current_user)
    if resposta_existente&.submitted?
      flash[:alert] = "Você já respondeu este formulário"
      redirect_to formularios_pendentes_path
      return
    end

    # Criar ou atualizar resposta
    @resposta = resposta_existente || Resposta.new(avaliacao: @avaliacao, dicente: current_user)
    
    # Processar respostas primeiro
    if processar_respostas(@resposta)
      @resposta.status = :submitted
      @resposta.submitted_at = Time.current
      
      if @resposta.save
        flash[:notice] = "Avaliação enviada com sucesso!"
        redirect_to formularios_pendentes_path
      else
        @questoes = @avaliacao.questoes.order(:position)
        flash.now[:alert] = @resposta.errors.full_messages.to_sentence.presence || "Erro ao enviar o formulário."
        render :responder, status: :unprocessable_entity
      end
    else
      @questoes = @avaliacao.questoes.order(:position)
      flash.now[:alert] = @resposta.errors.full_messages.to_sentence.presence || "Erro ao enviar o formulário. Verifique se todas as perguntas obrigatórias foram respondidas."
      render :responder, status: :unprocessable_entity
    end
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

    # Verificar todas as questões obrigatórias primeiro
    questoes_obrigatorias = @avaliacao.questoes.where(mandatory: true)
    questoes_obrigatorias.each do |questao|
      valor = params[:respostas][questao.id.to_s]
      if valor.blank?
        resposta.errors.add(:base, "A pergunta '#{questao.prompt}' é obrigatória")
        return false
      end
    end

    # Processar todas as respostas
    params[:respostas].each do |questao_id, valor|
      questao = Questao.find_by(id: questao_id)
      next unless questao && questao.avaliacao == @avaliacao

      # Criar ou atualizar resposta_item
      resposta_item = resposta.resposta_items.find_or_initialize_by(questao: questao)
      resposta_item.valor = valor.to_s
      
      unless resposta_item.save
        resposta.errors.add(:base, "Erro ao salvar resposta para '#{questao.prompt}'")
        return false
      end
    end

    true
  end
end
