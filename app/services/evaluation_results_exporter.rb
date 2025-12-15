require "csv"

##
# Service for exporting evaluation results to CSV format.
<<<<<<< HEAD
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
  # Custom error class for export failures.
=======
# Generates a CSV file containing all responses to an evaluation.
#
class EvaluationResultsExporter
  ##
  # Exception raised when export fails.
>>>>>>> sprint-3-documentacao
  #
  class ExportError < StandardError; end

  class << self
    attr_accessor :force_failure
  end

  ##
<<<<<<< HEAD
  # Initializes exporter with an evaluation.
  #
  # ==== Parameters
  # * +avaliacao+ - Avaliacao instance to export results from
=======
  # Initializes a new exporter for the given evaluation.
  #
  # ==== Parameters
  # * +avaliacao+ - Avaliacao object to export results for
>>>>>>> sprint-3-documentacao
  #
  def initialize(avaliacao)
    @avaliacao = avaliacao
  end

  ##
<<<<<<< HEAD
  # Executes the CSV export.
  #
  # ==== Returns
  # * String - CSV formatted content
  #
  # ==== Raises
  # * +ExportError+ - If no responses or export fails
=======
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
>>>>>>> sprint-3-documentacao
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
<<<<<<< HEAD
=======
  # ==== Raises
  # * StandardError - If service is forced to fail (testing)
  # * ExportError - If no responses are available
  #
>>>>>>> sprint-3-documentacao
  def validate_export_conditions
    raise StandardError, "Serviço de exportação indisponível" if self.class.force_failure
    raise ExportError, "Ainda não há respostas disponíveis" if @avaliacao.respostas.none?
  end

  ##
<<<<<<< HEAD
  # Generates the CSV content.
=======
  # Generates CSV content with headers and rows.
  #
  # ==== Returns
  # * String - Complete CSV content
>>>>>>> sprint-3-documentacao
  #
  def generate_csv_report
    CSV.generate(headers: true) do |csv|
      add_csv_header(csv)
      add_csv_rows(csv)
    end
  end

  ##
<<<<<<< HEAD
  # Adds header row to CSV.
=======
  # Adds CSV header row.
  #
  # ==== Parameters
  # * +csv+ - CSV object to write to
  #
  # ==== Side Effects
  # * Writes header row to CSV
>>>>>>> sprint-3-documentacao
  #
  def add_csv_header(csv)
    csv << ["Questão", "Aluno", "Resposta", "Enviado em"]
  end

  ##
  # Adds all data rows to CSV.
  #
<<<<<<< HEAD
=======
  # ==== Parameters
  # * +csv+ - CSV object to write to
  #
  # ==== Side Effects
  # * Writes data rows to CSV
  #
>>>>>>> sprint-3-documentacao
  def add_csv_rows(csv)
    @avaliacao.questoes.includes(resposta_items: :resposta).each do |questao|
      add_questao_rows(csv, questao)
    end
  end

  ##
<<<<<<< HEAD
  # Adds rows for a single question.
=======
  # Adds rows for a specific question.
  #
  # ==== Parameters
  # * +csv+ - CSV object to write to
  # * +questao+ - Questao object
  #
  # ==== Side Effects
  # * Writes rows for each response to the question
>>>>>>> sprint-3-documentacao
  #
  def add_questao_rows(csv, questao)
    questao.resposta_items.each do |item|
      csv << build_csv_row(questao, item)
    end
  end

  ##
<<<<<<< HEAD
  # Builds a single CSV row.
=======
  # Builds a CSV row from question and response item.
  #
  # ==== Parameters
  # * +questao+ - Questao object
  # * +item+ - RespostaItem object
  #
  # ==== Returns
  # * Array - CSV row data [question prompt, student name, response value, submitted_at]
>>>>>>> sprint-3-documentacao
  #
  def build_csv_row(questao, item)
    [questao.prompt, item.resposta.dicente.nome, item.valor, item.resposta.submitted_at]
  end
<<<<<<< HEAD

  public

  ##
  # Generates the filename for the CSV download.
  #
  # ==== Returns
  # * String - Parameterized filename with .csv extension
  #
  def filename
    parameterized = @avaliacao.title.parameterize
    "#{parameterized}-resultados.csv"
  end
=======
>>>>>>> sprint-3-documentacao
end
