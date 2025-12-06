class RespostaItem < ApplicationRecord
  belongs_to :resposta
  belongs_to :questao

  validates :valor, presence: true
  validates :questao_id, uniqueness: { scope: :resposta_id }
end
