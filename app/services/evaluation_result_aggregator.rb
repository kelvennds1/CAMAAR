class EvaluationResultAggregator
  attr_reader :avaliacao

  def initialize(avaliacao)
    @avaliacao = avaliacao
  end

  def summary
    {
      total_responses: total_responses,
      completion_rate: completion_rate,
      average_score: average_score,
      question_stats: question_stats
    }
  end

  private

  def total_responses
    @total_responses ||= avaliacao.respostas.count
  end

  def completion_rate
    matriculas = avaliacao.turma.matriculas.count
    return 0 if matriculas.zero?

    ((total_responses.to_f / matriculas) * 100).round
  end

  def average_score
    avaliacao.respostas.average(:score)&.to_f&.round(2) || 0.0
  end

  def question_stats
    avaliacao.questoes.order(:position).map do |questao|
      distribution = questao.resposta_items.group(:valor).count
      total = distribution.values.sum

      {
        id: questao.id,
        prompt: questao.prompt,
        total: total,
        distribution: distribution
      }
    end
  end
end
