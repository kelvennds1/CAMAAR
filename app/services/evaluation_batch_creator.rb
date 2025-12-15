class EvaluationBatchCreator
  Result = Struct.new(:created, :skipped, :errors, keyword_init: true) do
    def success?
      errors.blank?
    end
  end

  def self.call(**kwargs)
    new(**kwargs).call
  end

  def initialize(template_id:, turma_ids:, due_date: nil)
    @template_id = template_id
    @turma_ids = Array(turma_ids).reject(&:blank?)
    @due_date_param = due_date
  end

  def call
    return error_result("Selecione ao menos um template e uma turma") if invalid_params?

    template, turmas = load_template_and_turmas
    created, skipped = process_turmas(template, turmas)

    Result.new(created:, skipped:, errors: [])
  rescue ActiveRecord::RecordInvalid => e
    handle_record_invalid(e)
  rescue ActiveRecord::RecordNotFound
    error_result("Template selecionado não foi encontrado")
  end

  private

  def error_result(message)
    Result.new(created: [], skipped: [], errors: [message])
  end

  def load_template_and_turmas
    template = Template.includes(:template_questions).find(@template_id)
    turmas = Turma.includes(:docente).where(id: @turma_ids)
    [template, turmas]
  end

  def process_turmas(template, turmas)
    created = []
    skipped = []

    ApplicationRecord.transaction do
      turmas.each do |turma|
        process_single_turma(turma, template, created, skipped)
      end
    end

    [created, skipped]
  end

  def process_single_turma(turma, template, created, skipped)
    if duplicate?(turma, template)
      skipped << turma
    else
      created << create_avaliacao_for_turma(turma, template)
    end
  end

  def create_avaliacao_for_turma(turma, template)
    avaliacao = Avaliacao.create!(build_evaluation_attributes(template, turma))
    copy_questions(template, avaliacao)
    avaliacao
  end

  def handle_record_invalid(error)
    message = error.record.errors.full_messages.to_sentence.presence || error.message
    error_result(message)
  end

  def invalid_params?
    @template_id.blank? || @turma_ids.empty?
  end

  def duplicate?(turma, template)
    Avaliacao.exists?(turma_id: turma.id, template_id: template.id)
  end

  def build_evaluation_attributes(template, turma)
    {
      template: template,
      turma: turma,
      docente: turma.docente,
      title: "#{template.name} - #{turma.class_code}/#{turma.semester}",
      description: template.description,
      due_date: normalized_due_date,
      max_score: max_score_for(template)
    }
  end

  def max_score_for(template)
    template.template_questions.count * 5
  end

  def normalized_due_date
    parsed = if @due_date_param.present?
               Time.zone.parse(@due_date_param) rescue nil
             end
    parsed || Time.zone.today.end_of_month
  end

  def copy_questions(template, avaliacao)
    template.template_questions.order(:position).each do |template_question|
      avaliacao.questoes.create!(
        prompt: template_question.prompt,
        question_type: template_question.question_type,
        position: template_question.position,
        mandatory: template_question.required,
        min_value: template_question.min_value,
        max_value: template_question.max_value,
        options: template_question.options,
        template_question: template_question,
        weight: 1
      )
    end
  end
end
