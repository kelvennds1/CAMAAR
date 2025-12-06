class Matricula < ApplicationRecord
  belongs_to :dicente
  belongs_to :turma

  enum :status, {
    ativo: "ativo",
    trancado: "trancado",
    concluido: "concluido"
  }

  validates :dicente_id, uniqueness: { scope: :turma_id }
end
