##
# Model representing a question in an evaluation.
# Questions are created from template questions when an evaluation is generated.
#
# ==== Associations
# * belongs_to :avaliacao - The evaluation this question belongs to
# * belongs_to :template_question - The template question this was created from (optional)
# * has_many :resposta_items - Student responses to this question
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
  # Checks if this question accepts numeric responses (Likert scale).
  #
  # ==== Returns
  # * Boolean - true if question_type is likert, false otherwise
  #
  def numeric?
    question_type == QUESTION_TYPES[:likert]
  end
end
