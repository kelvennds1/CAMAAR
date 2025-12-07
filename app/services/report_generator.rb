class ReportGenerator
  def initialize(scope = Avaliacao.all)
    @scope = scope
  end

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

  def evaluations
    @evaluations ||= begin
      if scope.respond_to?(:includes)
        scope.includes(:docente, turma: :materia).to_a
      else
        Array(scope)
      end
    end
  end

  def aggregator_for(avaliacao)
    EvaluationResultAggregator.new(avaliacao)
  end
end
