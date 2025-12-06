class Questao < ApplicationRecord
  self.table_name = "questoes"

  QUESTION_TYPES = TemplateQuestion::QUESTION_TYPES

  belongs_to :avaliacao
  belongs_to :template_question, optional: true

  has_many :resposta_items, dependent: :destroy

  validates :prompt, :question_type, :position, :weight, presence: true
  validates :question_type, inclusion: { in: QUESTION_TYPES.values }
  validates :position, numericality: { greater_than: 0 }

  def numeric?
    question_type == QUESTION_TYPES[:likert]
  end
end
