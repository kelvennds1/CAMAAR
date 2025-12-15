class TemplateQuestion < ApplicationRecord
  QUESTION_TYPES = {
    likert: "likert",
    multiple_choice: "multiple_choice",
    text: "text"
  }.freeze

  attr_accessor :options_text

  belongs_to :template, inverse_of: :template_questions

  before_validation :normalize_fields

  validates :prompt, :question_type, :position, presence: true
  validates :question_type, inclusion: { in: QUESTION_TYPES.values }
  validates :position, numericality: { greater_than: 0 }
  validate :validate_multiple_choice_options
  validate :validate_likert_scale

  def options_array
    (options.presence && JSON.parse(options)) || []
  rescue JSON::ParserError
    []
  end

  def options_text
    @options_text.presence || options_array.join("\n")
  end

  private

  ##
  # Normalizes and cleans field values before validation.
  # Delegates to type-specific normalizers.
  #
  def normalize_fields
    normalize_basic_fields
    normalize_by_question_type
  end

  ##
  # Normalizes common fields for all question types.
  #
  def normalize_basic_fields
    self.question_type = question_type.presence&.downcase
    self.position ||= calculate_default_position
  end

  ##
  # Calculates default position based on existing questions.
  #
  def calculate_default_position
    template&.template_questions&.size.to_i + 1
  end

  ##
  # Normalizes fields based on question type.
  #
  def normalize_by_question_type
    case question_type
    when QUESTION_TYPES[:multiple_choice]
      normalize_multiple_choice_fields
    when QUESTION_TYPES[:likert]
      normalize_likert_fields
    else
      clear_type_specific_fields
    end
  end

  ##
  # Normalizes fields for multiple choice questions.
  #
  def normalize_multiple_choice_fields
    store_options_payload
    self.min_value = nil
    self.max_value = nil
  end

  ##
  # Normalizes fields for Likert scale questions.
  #
  def normalize_likert_fields
    self.min_value = (min_value.presence || 1).to_i
    self.max_value = (max_value.presence || 5).to_i
    self.options = nil
  end

  ##
  # Clears type-specific fields (for text questions).
  #
  def clear_type_specific_fields
    self.options = nil
    self.min_value = nil
    self.max_value = nil
  end

  def store_options_payload
    collection = parsed_options_from_accessor
    self.options = collection.any? ? collection.to_json : nil
  end

  def parsed_options_from_accessor
    source = if @options_text.nil?
               options_array
             else
               @options_text.to_s.split(/\r?\n/)
             end

    source.map(&:strip).reject(&:blank?).uniq
  end

  def validate_multiple_choice_options
    return unless question_type == QUESTION_TYPES[:multiple_choice]

    if options_array.length < 2
      errors.add(:options, "Adicione pelo menos duas opções")
    end
  end

  ##
  # Validates Likert scale configuration.
  # Delegates to specific validators for clarity.
  #
  def validate_likert_scale
    return unless question_type == QUESTION_TYPES[:likert]
    return if valid_likert_configuration?

    errors.add(:base, "A escala numérica deve ser de 1 a 5")
  end

  ##
  # Checks if Likert scale has valid configuration.
  #
  def valid_likert_configuration?
    values_present? && values_in_range? && min_less_than_max?
  end

  def values_present?
    min_value.present? && max_value.present?
  end

  def values_in_range?
    min_value >= 1 && max_value <= 5
  end

  def min_less_than_max?
    min_value < max_value
  end
end
