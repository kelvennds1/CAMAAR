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

  def normalize_fields
    self.question_type = question_type.presence&.downcase
    self.position ||= template&.template_questions&.size.to_i + 1

    case question_type
    when QUESTION_TYPES[:multiple_choice]
      store_options_payload
      self.min_value = nil
      self.max_value = nil
    when QUESTION_TYPES[:likert]
      self.min_value = (min_value.presence || 1).to_i
      self.max_value = (max_value.presence || 5).to_i
      self.options = nil
    else
      self.options = nil
      self.min_value = nil
      self.max_value = nil
    end
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

  def validate_likert_scale
    return unless question_type == QUESTION_TYPES[:likert]

    unless min_value.present? && max_value.present? && min_value >= 1 && max_value <= 5 && min_value < max_value
      errors.add(:base, "A escala numérica deve ser de 1 a 5")
    end
  end
end
