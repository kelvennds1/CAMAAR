##
# Model representing a student enrollment in a class.
# Links a Dicente to a Turma.
#
# ==== Attributes
# * +status+ - Enrollment status (ativo, trancado, concluido)
#
# ==== Associations
# * +dicente+ - Student enrolled
# * +turma+ - Class the student is enrolled in
#
# ==== Validations
# * One enrollment per student per class (unique dicente_id + turma_id)
#
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
