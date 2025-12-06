class ResultadosController < ApplicationController
  before_action :load_avaliacao, only: %i[show export]

  def index
    @query = params[:q].to_s.strip
    @semester_filter = params[:semester].presence
    @avaliacoes = filtered_avaliacoes
    @search_performed = @query.present?
    @semester_options = semester_filters
  end

  def show
    @summary = EvaluationResultAggregator.new(@avaliacao).summary
  end

  def export
    exporter = EvaluationResultsExporter.new(@avaliacao)
    send_data exporter.call,
          type: "text/csv",
          disposition: "attachment",
          filename: exporter.filename
  rescue EvaluationResultsExporter::ExportError => e
    redirect_to resultado_path(@avaliacao), alert: export_error_message(e)
  rescue StandardError
    redirect_to resultado_path(@avaliacao), alert: "Não foi possível gerar o arquivo. Tente novamente mais tarde."
  end

  private

  def filtered_avaliacoes
    scope = Avaliacao.includes(:turma, :docente).order(created_at: :desc)
    scope = scope.where(turma: { semester: @semester_filter }) if @semester_filter
    return scope unless @query.present?

    query = "%#{@query.downcase}%"
    scope.left_joins(:docente).where(
      "LOWER(avaliacoes.title) LIKE :q OR LOWER(usuarios.nome) LIKE :q",
      q: query
    )
  end

  def load_avaliacao
    @avaliacao = Avaliacao.includes(:turma, :docente, questoes: { resposta_items: :resposta }).find_by(id: params[:id])
    return if @avaliacao

    redirect_to resultados_path, alert: "O formulário solicitado não foi encontrado"
  end

  def semester_filters
    current = current_semester
    [["Todos", ""], [current, current]]
  end

  def current_semester
    date = Time.zone.today
    term = date.month <= 6 ? 1 : 2
    format('%<year>d.%<term>d', year: date.year, term: term)
  end

  def export_error_message(error)
    return error.message if error.message == "Ainda não há respostas disponíveis"

    "Não foi possível gerar o arquivo. Tente novamente mais tarde."
  end
end
