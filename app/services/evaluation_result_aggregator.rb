##
# Service for aggregating evaluation results and statistics.
# Provides summary data for a single evaluation including response rates,
# average scores, and per-question statistics.
# Provides summary data including response counts, completion rates, and question statistics.
#
# ==== Usage
#   aggregator = EvaluationResultAggregator.new(avaliacao)
#   summary = aggregator.summary
#   # => { total_responses: 25, completion_rate: 80, average_score: 4.2, question_stats: [...] }
#
class EvaluationResultAggregator
  attr_reader :avaliacao

  ##
  # Initializes a new aggregator for the given evaluation.
  #
  # ==== Parameters
  # * +avaliacao+ - Avaliacao object to aggregate results for
  #
  def initialize(avaliacao)
    @avaliacao = avaliacao
  end

  ##
  # Generates a comprehensive summary of evaluation results.
  #
  # ==== Returns
  # * Hash - Contains:
  #   * :total_responses (Integer) - Number of submitted responses
  #   * :completion_rate (Integer) - Percentage of enrolled students who responded
  #   * :average_score (Float) - Average score across all responses
  #   * :question_stats (Array) - Statistics for each question
  #
  # ==== Side Effects
  # * None - This is a read-only operation
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
  # Counts total number of submitted responses.
  #
  # ==== Returns
  # * Integer - Number of respostas with submitted status
  #
  def total_responses
    @total_responses ||= avaliacao.respostas.count
  end

  ##
  # Calculates the completion rate as percentage of enrolled students who responded.
  #
  # ==== Returns
  # * Integer - Completion rate percentage (0-100), or 0 if no enrollments
  #
  def completion_rate
    matriculas = avaliacao.turma.matriculas.count
    return 0 if matriculas.zero?

    ((total_responses.to_f / matriculas) * 100).round
  end

  ##
  # Calculates the average score across all responses.
  #
  # ==== Returns
  # * Float - Average score rounded to 2 decimal places, or 0.0 if no responses
  #
  def average_score
    avaliacao.respostas.average(:score)&.to_f&.round(2) || 0.0
  end

  ##
  # Generates statistics for each question in the evaluation.
  #
  # ==== Returns
  # * Array - Array of hashes, each containing:
  #   * :id (Integer) - Question ID
  #   * :prompt (String) - Question text
  #   * :total (Integer) - Total number of responses to this question
  #   * :distribution (Hash) - Distribution of response values
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
