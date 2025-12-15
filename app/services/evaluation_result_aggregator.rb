##
# Service for aggregating evaluation results and statistics.
# Provides summary data for a single evaluation including response rates,
# average scores, and per-question statistics.
#
# ==== Usage
#   aggregator = EvaluationResultAggregator.new(avaliacao)
#   summary = aggregator.summary
#   # => { total_responses: 25, completion_rate: 80, average_score: 4.2, question_stats: [...] }
#
class EvaluationResultAggregator
  attr_reader :avaliacao

  ##
  # Initializes the aggregator with an evaluation.
  #
  # ==== Parameters
  # * +avaliacao+ - Avaliacao instance to aggregate results for
  #
  def initialize(avaliacao)
    @avaliacao = avaliacao
  end

  ##
  # Generates a complete summary of evaluation results.
  #
  # ==== Returns
  # * Hash containing:
  #   - +total_responses+ - Number of submitted responses
  #   - +completion_rate+ - Percentage of enrolled students who responded
  #   - +average_score+ - Average score across all responses
  #   - +question_stats+ - Array of per-question statistics
  #
  def summary
    {
      total_responses: total_responses,
      completion_rate: completion_rate,
      average_score: average_score,
      question_stats: question_stats
    }
  end

  private

  ##
  # Counts total submitted responses.
  #
  def total_responses
    @total_responses ||= avaliacao.respostas.count
  end

  ##
  # Calculates completion rate as percentage.
  #
  def completion_rate
    matriculas = avaliacao.turma.matriculas.count
    return 0 if matriculas.zero?

    ((total_responses.to_f / matriculas) * 100).round
  end

  ##
  # Calculates average response score.
  #
  def average_score
    avaliacao.respostas.average(:score)&.to_f&.round(2) || 0.0
  end

  ##
  # Generates statistics for each question.
  #
  # ==== Returns
  # * Array of hashes with id, prompt, total, and distribution
  #
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
