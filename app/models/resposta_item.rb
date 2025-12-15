##
# Model representing an individual answer to a question.
# Each RespostaItem corresponds to one question's answer in a Resposta.
#
# ==== Attributes
# * +valor+ - The answer value (text, number, or selected option)
#
# ==== Associations
# * +resposta+ - Parent response this answer belongs to
# * +questao+ - Question being answered
#
# ==== Validations
# * One answer per question per response (unique questao_id + resposta_id)
#
class RespostaItem < ApplicationRecord
  belongs_to :resposta
  belongs_to :questao

  validates :valor, presence: true
  validates :questao_id, uniqueness: { scope: :resposta_id }
end
