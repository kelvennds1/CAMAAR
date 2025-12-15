##
# Model representing an evaluation form (Avaliacao).
# An evaluation is created from a template and assigned to one or more classes (turmas).
#
# ==== Associations
# * belongs_to :turma - The class this evaluation is assigned to
# * belongs_to :docente - The teacher who created this evaluation
# * belongs_to :template - The template used to create this evaluation (optional)
# * has_many :questoes - Questions in this evaluation
# * has_many :respostas - Student responses to this evaluation
#
class Avaliacao < ApplicationRecord
  self.table_name = "avaliacoes"

  enum :status, {
    draft: "draft",
    published: "published",
    closed: "closed"
  }

  belongs_to :turma
  belongs_to :docente
  belongs_to :template, optional: true

  has_many :questoes, dependent: :destroy
  has_many :respostas, dependent: :destroy

  accepts_nested_attributes_for :questoes, allow_destroy: true

  validates :title, :due_date, presence: true
  validates :max_score, numericality: { greater_than_or_equal_to: 0 }

  ##
  # Finds all pending evaluations for a given student.
  #
  # ==== Parameters
  # * +dicente+ - Dicente object representing the student
  #
  # ==== Returns
  # * ActiveRecord::Relation - Collection of published Avaliacao records
  #   that the student is enrolled in but hasn't responded to yet
  #
  # ==== Side Effects
  # * None - This is a query scope
  #
  scope :pending_for_dicente, lambda { |dicente|
    published
      .joins(turma: :matriculas)
      .where(matriculas: { dicente_id: dicente.id })
      .where.not(
        id: Resposta.where(dicente_id: dicente.id).select(:avaliacao_id)
      )
  }
end
