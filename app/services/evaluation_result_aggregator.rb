##
<<<<<<< HEAD
# Service for aggregating evaluation results and statistics.
# Provides summary data for a single evaluation including response rates,
# average scores, and per-question statistics.
#
# ==== Usage
#   aggregator = EvaluationResultAggregator.new(avaliacao)
#   summary = aggregator.summary
#   # => { total_responses: 25, completion_rate: 80, average_score: 4.2, question_stats: [...] }
=======
# Service for aggregating and calculating statistics for evaluation results.
# Provides summary data including response counts, completion rates, and question statistics.
>>>>>>> sprint-3-documentacao
#
class EvaluationResultAggregator
  attr_reader :avaliacao

  ##
<<<<<<< HEAD
  # Initializes the aggregator with an evaluation.
  #
  # ==== Parameters
  # * +avaliacao+ - Avaliacao instance to aggregate results for
=======
  # Initializes a new aggregator for the given evaluation.
  #
  # ==== Parameters
  # * +avaliacao+ - Avaliacao object to aggregate results for
>>>>>>> sprint-3-documentacao
  #
  def initialize(avaliacao)
    @avaliacao = avaliacao
  end

  ##
<<<<<<< HEAD
  # Generates a complete summary of evaluation results.
  #
  # ==== Returns
  # * Hash containing:
  #   - +total_responses+ - Number of submitted responses
  #   - +completion_rate+ - Percentage of enrolled students who responded
  #   - +average_score+ - Average score across all responses
  #   - +question_stats+ - Array of per-question statistics
=======
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
>>>>>>> sprint-3-documentacao
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
<<<<<<< HEAD
  # Counts total submitted responses.
=======
  # Counts total number of submitted responses.
  #
  # ==== Returns
  # * Integer - Number of respostas with submitted status
>>>>>>> sprint-3-documentacao
  #
  def total_responses
    @total_responses ||= avaliacao.respostas.count
  end

  ##
<<<<<<< HEAD
  # Calculates completion rate as percentage.
=======
  # Calculates the completion rate as percentage of enrolled students who responded.
  #
  # ==== Returns
  # * Integer - Completion rate percentage (0-100), or 0 if no enrollments
>>>>>>> sprint-3-documentacao
  #
  def completion_rate
    matriculas = avaliacao.turma.matriculas.count
    return 0 if matriculas.zero?

    ((total_responses.to_f / matriculas) * 100).round
  end

  ##
<<<<<<< HEAD
  # Calculates average response score.
=======
  # Calculates the average score across all responses.
  #
  # ==== Returns
  # * Float - Average score rounded to 2 decimal places, or 0.0 if no responses
>>>>>>> sprint-3-documentacao
  #
  def average_score
    avaliacao.respostas.average(:score)&.to_f&.round(2) || 0.0
  end

  ##
<<<<<<< HEAD
  # Generates statistics for each question.
  #
  # ==== Returns
  # * Array of hashes with id, prompt, total, and distribution
=======
  # Generates statistics for each question in the evaluation.
  #
  # ==== Returns
  # * Array - Array of hashes, each containing:
  #   * :id (Integer) - Question ID
  #   * :prompt (String) - Question text
  #   * :total (Integer) - Total number of responses to this question
  #   * :distribution (Hash) - Distribution of response values
>>>>>>> sprint-3-documentacao
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
