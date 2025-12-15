##
# Controller for viewing and exporting evaluation results.
# Handles displaying evaluation statistics and exporting data to CSV.
#
class ResultadosController < ApplicationController
  before_action :load_avaliacao, only: %i[show export]

  ##
  # Lists all evaluations with optional search and semester filtering.
  #
  # ==== Parameters
  # * +params[:q]+ - String with search query (optional)
  # * +params[:semester]+ - String with semester filter (optional)
  #
  # ==== Returns
  # * Renders index view with filtered evaluations list
  #
  # ==== Side Effects
  # * Sets @query, @semester_filter, @avaliacoes, @search_performed, @semester_options instance variables
  #
  def index
    @query = params[:q].to_s.strip
    @semester_filter = params[:semester].presence
    @avaliacoes = filtered_avaliacoes
    @search_performed = @query.present?
    @semester_options = semester_filters
  end

  ##
  # Displays detailed results for a specific evaluation.
  #
  # ==== Parameters
  # * +params[:id]+ - Integer with Avaliacao ID
  #
  # ==== Returns
  # * Renders show view with evaluation summary statistics
  #
  # ==== Side Effects
  # * Sets @avaliacao and @summary instance variables
  #
  def show
    @summary = EvaluationResultAggregator.new(@avaliacao).summary
  end

  ##
  # Exports evaluation results to CSV format.
  #
  # ==== Parameters
  # * +params[:id]+ - Integer with Avaliacao ID
  #
  # ==== Returns
  # * Sends CSV file as download attachment on success
  # * Redirects to resultado_path with error message on failure
  #
  # ==== Side Effects
  # * Generates CSV file with evaluation responses
  # * Sets flash[:alert] on error
  #
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

  ##
  # Filters evaluations based on search query and semester.
  #
  # ==== Returns
  # * ActiveRecord::Relation - Filtered collection of Avaliacao records
  #
  # ==== Side Effects
  # * None - This is a query method
  #
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

  ##
  # Loads the avaliacao from database and handles not found cases.
  #
  # ==== Parameters
  # * +params[:id]+ - Integer with Avaliacao ID
  #
  # ==== Returns
  # * nil - Sets @avaliacao instance variable
  #
  # ==== Side Effects
  # * Sets @avaliacao instance variable
  # * Redirects to resultados_path with error message if not found
  #
  def load_avaliacao
    @avaliacao = Avaliacao.includes(:turma, :docente, questoes: { resposta_items: :resposta }).find_by(id: params[:id])
    return if @avaliacao

    redirect_to resultados_path, alert: "O formulário solicitado não foi encontrado"
  end

  ##
  # Generates semester filter options for the view.
  #
  # ==== Returns
  # * Array - Array of arrays with ["Label", "value"] format
  #
  # ==== Side Effects
  # * None
  #
  def semester_filters
    current = current_semester
    [["Todos", ""], [current, current]]
  end

  ##
  # Calculates the current semester based on today's date.
  #
  # ==== Returns
  # * String - Semester in format "YYYY.T" (e.g., "2024.1" or "2024.2")
  #
  # ==== Side Effects
  # * None
  #
  def current_semester
    date = Time.zone.today
    term = date.month <= 6 ? 1 : 2
    format('%<year>d.%<term>d', year: date.year, term: term)
  end

  ##
  # Generates error message for export failures.
  #
  # ==== Parameters
  # * +error+ - Exception object (usually ExportError)
  #
  # ==== Returns
  # * String - Error message to display to user
  #
  # ==== Side Effects
  # * None
  #
  def export_error_message(error)
    return error.message if error.message == "Ainda não há respostas disponíveis"

    "Não foi possível gerar o arquivo. Tente novamente mais tarde."
  end
end
