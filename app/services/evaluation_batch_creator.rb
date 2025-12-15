##
# Service for creating evaluation batches from a template.
# Creates one Avaliacao per selected Turma, copying questions from the template.
# Creates multiple Avaliacao records and their associated Questao records
# for multiple classes (turmas) at once.
#
# ==== Usage
#   result = EvaluationBatchCreator.call(
#     template_id: 1,
#     turma_ids: [1, 2, 3],
#     due_date: "2024-12-31"
#   )
#
#   if result.success?
#     puts "Created: #{result.created.size}, Skipped: #{result.skipped.size}"
#   else
#     puts "Errors: #{result.errors.join(', ')}"
#   end
#
class EvaluationBatchCreator
  ##
  # Result object containing creation statistics.
  # * +created+ - Array of created Avaliacao records
  # * +skipped+ - Array of Turma records skipped (already had evaluation)
  # * +errors+ - Array of error messages
  #
  Result = Struct.new(:created, :skipped, :errors, keyword_init: true) do
    ##
    # Checks if the batch creation was successful.
    #
    # ==== Returns
    # * Boolean - true if no errors occurred, false otherwise
    #
    def success?
      errors.blank?
    end
  end

  ##
  # Class method to create evaluation batches.
  #
  # ==== Parameters
  # * +template_id:+ - Integer with Template ID to use
  # * +turma_ids:+ - Array of Integer with Turma IDs to create evaluations for
  # * +due_date:+ - String or Date with due date (optional, defaults to end of month)
  #
  # ==== Returns
  # * Result - Object with created, skipped arrays and errors array
  #
  # ==== Side Effects
  # * Creates Avaliacao records in database
  # * Creates Questao records for each avaliacao
  # * Skips turmas that already have an evaluation for the given template
  #
  def self.call(**kwargs)
    new(**kwargs).call
  end

  ##
  # Initializes a new EvaluationBatchCreator.
  #
  # ==== Parameters
  # * +template_id:+ - Integer with Template ID
  # * +turma_ids:+ - Array of Integer with Turma IDs
  # * +due_date:+ - String or Date with due date (optional)
  #
  def initialize(template_id:, turma_ids:, due_date: nil)
    @template_id = template_id
    @turma_ids = Array(turma_ids).reject(&:blank?)
    @due_date_param = due_date
  end

  ##
  # Executes the batch creation process.
  #
  # ==== Returns
  # * Result - Object with created, skipped arrays and errors array
  #
  # ==== Side Effects
  # * Creates Avaliacao and Questao records in database
  # * Wraps operations in a database transaction
  #
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

  ##
  # Creates an error result object.
  #
  # ==== Parameters
  # * +message+ - String with error message
  #
  # ==== Returns
  # * Result - Result object with error message
  #
  def error_result(message)
    Result.new(created: [], skipped: [], errors: [message])
  end

  ##
  # Loads template and turmas from database.
  #
  # ==== Returns
  # * Array - [Template, ActiveRecord::Relation<Turma>]
  #
  # ==== Side Effects
  # * Queries database for Template and Turma records
  #
  def load_template_and_turmas
    template = Template.includes(:template_questions).find(@template_id)
    turmas = Turma.includes(:docente).where(id: @turma_ids)
    [template, turmas]
  end

  ##
  # Processes all turmas and creates evaluations.
  #
  # ==== Parameters
  # * +template+ - Template object
  # * +turmas+ - ActiveRecord::Relation with Turma records
  #
  # ==== Returns
  # * Array - [Array<Avaliacao>, Array<Turma>] with created and skipped records
  #
  # ==== Side Effects
  # * Creates Avaliacao records in database
  # * Wraps operations in a transaction
  #
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

  ##
  # Processes a single turma and creates evaluation if needed.
  #
  # ==== Parameters
  # * +turma+ - Turma object
  # * +template+ - Template object
  # * +created+ - Array to append created Avaliacao to
  # * +skipped+ - Array to append skipped Turma to
  #
  # ==== Returns
  # * nil
  #
  # ==== Side Effects
  # * Creates Avaliacao record if not duplicate
  # * Modifies created and skipped arrays
  #
  def process_single_turma(turma, template, created, skipped)
    if duplicate?(turma, template)
      skipped << turma
    else
      created << create_avaliacao_for_turma(turma, template)
    end
  end

  ##
  # Creates an Avaliacao for a turma and copies questions from template.
  #
  # ==== Parameters
  # * +turma+ - Turma object
  # * +template+ - Template object
  #
  # ==== Returns
  # * Avaliacao - Newly created Avaliacao object
  #
  # ==== Side Effects
  # * Creates Avaliacao record in database
  # * Creates Questao records for the avaliacao
  #
  def create_avaliacao_for_turma(turma, template)
    avaliacao = Avaliacao.create!(build_evaluation_attributes(template, turma))
    copy_questions(template, avaliacao)
    avaliacao
  end

  ##
  # Handles RecordInvalid exceptions.
  #
  # ==== Parameters
  # * +error+ - ActiveRecord::RecordInvalid exception
  #
  # ==== Returns
  # * Result - Result object with error message
  #
  def handle_record_invalid(error)
    message = error.record.errors.full_messages.to_sentence.presence || error.message
    error_result(message)
  end

  ##
  # Checks if parameters are invalid.
  #
  # ==== Returns
  # * Boolean - true if template_id is blank or turma_ids is empty
  #
  def invalid_params?
    @template_id.blank? || @turma_ids.empty?
  end

  ##
  # Checks if an evaluation already exists for the turma and template.
  #
  # ==== Parameters
  # * +turma+ - Turma object
  # * +template+ - Template object
  #
  # ==== Returns
  # * Boolean - true if duplicate exists, false otherwise
  #
  # ==== Side Effects
  # * Queries database for existing Avaliacao
  #
  def duplicate?(turma, template)
    Avaliacao.exists?(turma_id: turma.id, template_id: template.id)
  end

  ##
  # Builds attributes hash for creating an Avaliacao.
  #
  # ==== Parameters
  # * +template+ - Template object
  # * +turma+ - Turma object
  #
  # ==== Returns
  # * Hash - Attributes hash for Avaliacao creation
  #
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

  ##
  # Calculates max score based on number of questions.
  #
  # ==== Parameters
  # * +template+ - Template object
  #
  # ==== Returns
  # * Integer - Max score (number of questions * 5)
  #
  def max_score_for(template)
    template.template_questions.count * 5
  end

  ##
  # Normalizes due date parameter to a Date object.
  #
  # ==== Returns
  # * Date - Parsed due date or end of current month as default
  #
  def normalized_due_date
    parsed = if @due_date_param.present?
               Time.zone.parse(@due_date_param) rescue nil
             end
    parsed || Time.zone.today.end_of_month
  end

  ##
  # Copies questions from template to avaliacao.
  #
  # ==== Parameters
  # * +template+ - Template object
  # * +avaliacao+ - Avaliacao object
  #
  # ==== Returns
  # * nil
  #
  # ==== Side Effects
  # * Creates Questao records in database
  #
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
