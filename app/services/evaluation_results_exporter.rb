require "csv"

class EvaluationResultsExporter
  class ExportError < StandardError; end

  class << self
    attr_accessor :force_failure
  end

  def initialize(avaliacao)
    @avaliacao = avaliacao
  end

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

  def validate_export_conditions
    raise StandardError, "Serviço de exportação indisponível" if self.class.force_failure
    raise ExportError, "Ainda não há respostas disponíveis" if @avaliacao.respostas.none?
  end

  def generate_csv_report
    CSV.generate(headers: true) do |csv|
      add_csv_header(csv)
      add_csv_rows(csv)
    end
  end

  def add_csv_header(csv)
    csv << ["Questão", "Aluno", "Resposta", "Enviado em"]
  end

  def add_csv_rows(csv)
    @avaliacao.questoes.includes(resposta_items: :resposta).each do |questao|
      add_questao_rows(csv, questao)
    end
  end

  def add_questao_rows(csv, questao)
    questao.resposta_items.each do |item|
      csv << build_csv_row(questao, item)
    end
  end

  def build_csv_row(questao, item)
    [questao.prompt, item.resposta.dicente.nome, item.valor, item.resposta.submitted_at]
  end

  public

  def filename
    parameterized = @avaliacao.title.parameterize
    "#{parameterized}-resultados.csv"
  end
end
