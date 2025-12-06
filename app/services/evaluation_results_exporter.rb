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
    raise StandardError, "Serviço de exportação indisponível" if self.class.force_failure
    raise ExportError, "Ainda não há respostas disponíveis" if @avaliacao.respostas.none?

    CSV.generate(headers: true) do |csv|
      csv << ["Questão", "Aluno", "Resposta", "Enviado em"]
      @avaliacao.questoes.includes(resposta_items: :resposta).each do |questao|
        questao.resposta_items.each do |item|
          csv << [questao.prompt, item.resposta.dicente.nome, item.valor, item.resposta.submitted_at]
        end
      end
    end
  rescue ExportError
    raise
  rescue StandardError => e
    raise ExportError, e.message
  ensure
    self.class.force_failure = false
  end

  def filename
    parameterized = @avaliacao.title.parameterize
    "#{parameterized}-resultados.csv"
  end
end
