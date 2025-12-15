require "csv"

##
# Service for exporting evaluation results to CSV format.
# Generates a downloadable report with all responses.
#
# ==== Usage
#   exporter = EvaluationResultsExporter.new(avaliacao)
#   csv_content = exporter.call
#   filename = exporter.filename
#
# ==== Raises
# * +ExportError+ - When there are no responses or export fails
#
class EvaluationResultsExporter
  ##
  # Exception raised when export fails.
  #
  class ExportError < StandardError; end

  class << self
    attr_accessor :force_failure
  end

  ##
  # Initializes a new exporter for the given evaluation.
  #
  # ==== Parameters
  # * +avaliacao+ - Avaliacao object to export results for
  #
  def initialize(avaliacao)
    @avaliacao = avaliacao
  end

  ##
  # Generates CSV content with evaluation results.
  #
  # ==== Returns
  # * String - CSV content with headers and all response data
  #
  # ==== Raises
  # * ExportError - If export conditions are not met or an error occurs
  #
  # ==== Side Effects
  # * Queries database for responses and questions
  #
  def call
    validate_export_conditions
    generate_csv_report
  rescue ExportError
    raise
  rescue StandardError => e
    raise ExportError, e.message
  ensure
    self.class.force_failure = false
  end

  ##
  # Generates filename for the exported CSV file.
  #
  # ==== Returns
  # * String - Filename based on evaluation title (e.g., "avaliacao-titulo-resultados.csv")
  #
  def filename
    parameterized = @avaliacao.title.parameterize
    "#{parameterized}-resultados.csv"
  end

  private

  ##
  # Validates that export can proceed.
  #
  # ==== Raises
  # * StandardError - If service is forced to fail (testing)
  # * ExportError - If no responses are available
  #
  def validate_export_conditions
    raise StandardError, "Serviço de exportação indisponível" if self.class.force_failure
    raise ExportError, "Ainda não há respostas disponíveis" if @avaliacao.respostas.none?
  end

  ##
  # Generates CSV content with headers and rows.
  #
  # ==== Returns
  # * String - Complete CSV content
  #
  def generate_csv_report
    CSV.generate(headers: true) do |csv|
      add_csv_header(csv)
      add_csv_rows(csv)
    end
  end

  ##
  # Adds CSV header row.
  #
  # ==== Parameters
  # * +csv+ - CSV object to write to
  #
  # ==== Side Effects
  # * Writes header row to CSV
  #
  def add_csv_header(csv)
    csv << ["Questão", "Aluno", "Resposta", "Enviado em"]
  end

  ##
  # Adds all data rows to CSV.
  #
  # ==== Parameters
  # * +csv+ - CSV object to write to
  #
  # ==== Side Effects
  # * Writes data rows to CSV
  #
  def add_csv_rows(csv)
    @avaliacao.questoes.includes(resposta_items: :resposta).each do |questao|
      add_questao_rows(csv, questao)
    end
  end

  ##
  # Adds rows for a specific question.
  #
  # ==== Parameters
  # * +csv+ - CSV object to write to
  # * +questao+ - Questao object
  #
  # ==== Side Effects
  # * Writes rows for each response to the question
  #
  def add_questao_rows(csv, questao)
    questao.resposta_items.each do |item|
      csv << build_csv_row(questao, item)
    end
  end

  ##
  # Builds a CSV row from question and response item.
  #
  # ==== Parameters
  # * +questao+ - Questao object
  # * +item+ - RespostaItem object
  #
  # ==== Returns
  # * Array - CSV row data [question prompt, student name, response value, submitted_at]
  #
  def build_csv_row(questao, item)
    [questao.prompt, item.resposta.dicente.nome, item.valor, item.resposta.submitted_at]
  end
end
