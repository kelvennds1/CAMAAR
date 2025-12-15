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
  # Custom error class for export failures.
  #
  class ExportError < StandardError; end

  class << self
    attr_accessor :force_failure
  end

  ##
  # Initializes exporter with an evaluation.
  #
  # ==== Parameters
  # * +avaliacao+ - Avaliacao instance to export results from
  #
  def initialize(avaliacao)
    @avaliacao = avaliacao
  end

  ##
  # Executes the CSV export.
  #
  # ==== Returns
  # * String - CSV formatted content
  #
  # ==== Raises
  # * +ExportError+ - If no responses or export fails
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

  private

  ##
  # Validates that export can proceed.
  #
  def validate_export_conditions
    raise StandardError, "Serviço de exportação indisponível" if self.class.force_failure
    raise ExportError, "Ainda não há respostas disponíveis" if @avaliacao.respostas.none?
  end

  ##
  # Generates the CSV content.
  #
  def generate_csv_report
    CSV.generate(headers: true) do |csv|
      add_csv_header(csv)
      add_csv_rows(csv)
    end
  end

  ##
  # Adds header row to CSV.
  #
  def add_csv_header(csv)
    csv << ["Questão", "Aluno", "Resposta", "Enviado em"]
  end

  ##
  # Adds all data rows to CSV.
  #
  def add_csv_rows(csv)
    @avaliacao.questoes.includes(resposta_items: :resposta).each do |questao|
      add_questao_rows(csv, questao)
    end
  end

  ##
  # Adds rows for a single question.
  #
  def add_questao_rows(csv, questao)
    questao.resposta_items.each do |item|
      csv << build_csv_row(questao, item)
    end
  end

  ##
  # Builds a single CSV row.
  #
  def build_csv_row(questao, item)
    [questao.prompt, item.resposta.dicente.nome, item.valor, item.resposta.submitted_at]
  end

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
end
