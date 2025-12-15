##
# Model representing a class section (turma).
# A turma is a specific offering of a subject in a given semester.
#
# ==== Attributes
# * +class_code+ - Class section code (e.g., "A", "B", "01")
# * +semester+ - Semester identifier (e.g., "2024.1", "2024.2")
#
# ==== Associations
# * +materia+ - Subject this class belongs to
# * +docente+ - Teacher assigned to this class
# * +matriculas+ - Student enrollments in this class
# * +dicentes+ - Students enrolled in this class (through matriculas)
# * +avaliacoes+ - Evaluations for this class
#
# ==== Validations
# * Unique class_code per materia per semester
#
class Turma < ApplicationRecord
  belongs_to :materia
  belongs_to :docente

  has_many :matriculas, dependent: :destroy
  has_many :dicentes, through: :matriculas
  has_many :avaliacoes, dependent: :destroy

  validates :class_code, :semester, presence: true
  validates :class_code, uniqueness: { scope: [:materia_id, :semester] }
end
