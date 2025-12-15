##
# Model representing an evaluation/assessment form.
# Contains questions that students must answer.
#
# ==== Attributes
# * +title+ - Evaluation title
# * +due_date+ - Deadline for responses
# * +status+ - Current status (draft, published, closed)
# * +max_score+ - Maximum possible score
#
# ==== Associations
# * +turma+ - Class this evaluation belongs to
# * +docente+ - Teacher responsible for this evaluation
# * +template+ - Template used to create this evaluation (optional)
# * +questoes+ - Questions in this evaluation
# * +respostas+ - Student responses to this evaluation
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
  # Scope to find evaluations pending for a specific student.
  #
  # ==== Parameters
  # * +dicente+ - Dicente instance to check pending evaluations for
  #
  # ==== Returns
  # * ActiveRecord::Relation of pending Avaliacao records
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
