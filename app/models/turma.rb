class Turma < ApplicationRecord
  belongs_to :materia
  belongs_to :docente

  has_many :matriculas, dependent: :destroy
  has_many :dicentes, through: :matriculas
  has_many :avaliacoes, dependent: :destroy

  validates :class_code, :semester, presence: true
  validates :class_code, uniqueness: { scope: [:materia_id, :semester] }
end
