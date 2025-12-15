##
# Model representing a student in the system.
# Inherits from Usuario (STI).
#
# ==== Attributes
# * +matricula+ - Student registration number
# * +curso+ - Student's course/program
#
# ==== Associations
# * +matriculas+ - Enrollments in classes
# * +turmas+ - Classes the student is enrolled in (through matriculas)
# * +avaliacoes+ - Evaluations available to this student (through turmas)
# * +respostas+ - Responses submitted by this student
#
class Dicente < Usuario
  has_many :matriculas, dependent: :destroy
  has_many :turmas, through: :matriculas
  has_many :avaliacoes, through: :turmas
  has_many :respostas, dependent: :destroy

  validates :matricula, :curso, presence: true
end
