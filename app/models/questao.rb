##
# Model representing a question in an evaluation.
# Questions are created from template_questions when an evaluation is generated.
#
# ==== Attributes
# * +prompt+ - Question text/statement
# * +question_type+ - Type of question (likert, multiple_choice, text)
# * +position+ - Order position in the evaluation
# * +weight+ - Score weight for this question
# * +mandatory+ - Whether the question must be answered
# * +options+ - JSON array of options (for multiple_choice)
# * +min_value+ / +max_value+ - Scale range (for likert)
#
# ==== Associations
# * +avaliacao+ - Evaluation this question belongs to
# * +template_question+ - Original template question (optional)
# * +resposta_items+ - Student answers to this question
#
class Questao < ApplicationRecord
  self.table_name = "questoes"

  QUESTION_TYPES = TemplateQuestion::QUESTION_TYPES

  belongs_to :avaliacao
  belongs_to :template_question, optional: true

  has_many :resposta_items, dependent: :destroy

  validates :prompt, :question_type, :position, :weight, presence: true
  validates :question_type, inclusion: { in: QUESTION_TYPES.values }
  validates :position, numericality: { greater_than: 0 }

  ##
  # Checks if question uses numeric (Likert) scale.
  #
  # ==== Returns
  # * Boolean - true if question is Likert type
  #
  def numeric?
    question_type == QUESTION_TYPES[:likert]
  end
end
