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
    return Result.new(created: [], skipped: [], errors: ["Selecione ao menos um template e uma turma"]) if invalid_params?

    template = Template.includes(:template_questions).find(@template_id)
    turmas = Turma.includes(:docente).where(id: @turma_ids)

    created = []
    skipped = []

    ApplicationRecord.transaction do
      turmas.each do |turma|
        if duplicate?(turma, template)
          skipped << turma
          next
        end

        avaliacao = Avaliacao.create!(build_evaluation_attributes(template, turma))
        copy_questions(template, avaliacao)
        created << avaliacao
      end
    end

    Result.new(created:, skipped:, errors: [])
  rescue ActiveRecord::RecordInvalid => e
    Result.new(created: [], skipped: [], errors: [e.record.errors.full_messages.to_sentence.presence || e.message])
  rescue ActiveRecord::RecordNotFound
    Result.new(created: [], skipped: [], errors: ["Template selecionado não foi encontrado"])
  end

  private

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
