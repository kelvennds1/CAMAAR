##
# Service for generating administrative reports across evaluations.
# Aggregates data from multiple evaluations for dashboard/reporting purposes.
#
# ==== Usage
#   # All evaluations
#   report = ReportGenerator.new
#   
#   # Specific scope
#   report = ReportGenerator.new(Avaliacao.where(status: :published))
#   
#   summary = report.summary  # Array of evaluation summaries
#   totals = report.totals    # Aggregate totals
#
class ReportGenerator
  ##
  # Initializes the generator with an optional scope.
  #
  # ==== Parameters
  # * +scope+ - ActiveRecord::Relation or Array of Avaliacao (default: all)
  #
  def initialize(scope = Avaliacao.all)
    @scope = scope
  end

  ##
  # Generates summary data for each evaluation in scope.
  #
  # ==== Returns
  # * Array of hashes with evaluation metrics:
  #   - +avaliacao_id+ - Evaluation ID
  #   - +title+ - Evaluation title
  #   - +docente+ - Teacher name
  #   - +semester+ - Semester identifier
  #   - +total_responses+ - Number of responses
  #   - +average_score+ - Average response score
  #   - +completion_rate+ - Response rate percentage
  #
  def summary
    @summary ||= evaluations.map do |avaliacao|
      metrics = aggregator_for(avaliacao).summary

      {
        avaliacao_id: avaliacao.id,
        title: avaliacao.title,
        docente: avaliacao.docente&.nome,
        semester: avaliacao.turma&.semester,
        total_responses: metrics[:total_responses],
        average_score: metrics[:average_score],
        completion_rate: metrics[:completion_rate]
      }
    end
  end

  ##
  # Calculates aggregate totals across all evaluations in scope.
  #
  # ==== Returns
  # * Hash containing:
  #   - +total_forms+ - Total number of evaluations
  #   - +total_responses+ - Sum of all responses
  #   - +average_completion_rate+ - Average completion rate
  #
  def totals
    data = summary
    total_forms = data.size
    total_responses = data.sum { |row| row[:total_responses].to_i }
    average_completion = if total_forms.zero?
      0
    else
      (data.sum { |row| row[:completion_rate].to_i }.to_f / total_forms).round
    end

    {
      total_forms: total_forms,
      total_responses: total_responses,
      average_completion_rate: average_completion
    }
  end

  private

  attr_reader :scope

  ##
  # Loads evaluations with eager loading for performance.
  #
  def evaluations
    @evaluations ||= begin
      if scope.respond_to?(:includes)
        scope.includes(:docente, turma: :materia).to_a
      else
        Array(scope)
      end
    end
  end

  ##
  # Creates aggregator instance for a single evaluation.
  #
  def aggregator_for(avaliacao)
    EvaluationResultAggregator.new(avaliacao)
  end
end
