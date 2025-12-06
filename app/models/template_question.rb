class TemplateQuestion < ApplicationRecord
  QUESTION_TYPES = {
    likert: "likert",
    multiple_choice: "multiple_choice",
    text: "text"
  }.freeze

  belongs_to :template

  validates :prompt, :question_type, :position, presence: true
  validates :question_type, inclusion: { in: QUESTION_TYPES.values }
  validates :position, numericality: { greater_than: 0 }

  def options_array
    (options.presence && JSON.parse(options)) || []
  rescue JSON::ParserError
    []
  end
end
