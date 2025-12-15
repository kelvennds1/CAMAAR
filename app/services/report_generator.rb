##
# Service for generating reports across multiple evaluations.
# Aggregates statistics from multiple evaluations for administrative reporting.
#
class ReportGenerator
  ##
  # Initializes a new report generator.
  #
  # ==== Parameters
  # * +scope+ - ActiveRecord::Relation or Array of Avaliacao records (default: Avaliacao.all)
  #
  def initialize(scope = Avaliacao.all)
    @scope = scope
  end

  ##
  # Generates summary statistics for all evaluations in scope.
  #
  # ==== Returns
  # * Array - Array of hashes, each containing:
  #   * :avaliacao_id (Integer) - Evaluation ID
  #   * :title (String) - Evaluation title
  #   * :docente (String) - Teacher name
  #   * :semester (String) - Semester code
  #   * :total_responses (Integer) - Number of responses
  #   * :average_score (Float) - Average score
  #   * :completion_rate (Integer) - Completion percentage
  #
  # ==== Side Effects
  # * None - This is a read-only operation
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
  # Calculates aggregate totals across all evaluations.
  #
  # ==== Returns
  # * Hash - Contains:
  #   * :total_forms (Integer) - Total number of evaluations
  #   * :total_responses (Integer) - Total responses across all evaluations
  #   * :average_completion_rate (Integer) - Average completion rate percentage
  #
  # ==== Side Effects
  # * None - This is a read-only operation
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
  # Loads evaluations from scope with necessary associations.
  #
  # ==== Returns
  # * Array - Array of Avaliacao objects with associations loaded
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
  # Creates an aggregator instance for a specific evaluation.
  #
  # ==== Parameters
  # * +avaliacao+ - Avaliacao object
  #
  # ==== Returns
  # * EvaluationResultAggregator - Aggregator instance
  #
  def aggregator_for(avaliacao)
    EvaluationResultAggregator.new(avaliacao)
  end
end
