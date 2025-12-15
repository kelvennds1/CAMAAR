##
# Model representing a teacher/professor in the system.
# Inherits from Usuario (STI).
#
# ==== Attributes
# * +departamento+ - Teacher's department
# * +titulacao+ - Academic title/degree
#
# ==== Associations
# * +turmas+ - Classes taught by this teacher
# * +templates+ - Evaluation templates created by this teacher
# * +avaliacoes+ - Evaluations associated with this teacher
#
class Docente < Usuario
  has_many :turmas, dependent: :nullify
  has_many :templates, dependent: :destroy
  has_many :avaliacoes, dependent: :nullify

  validates :departamento, :titulacao, presence: true
end
