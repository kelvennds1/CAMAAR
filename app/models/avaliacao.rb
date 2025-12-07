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

  scope :pending_for_dicente, lambda { |dicente|
    published
      .joins(turma: :matriculas)
      .where(matriculas: { dicente_id: dicente.id })
      .where.not(
        id: Resposta.where(dicente_id: dicente.id).select(:avaliacao_id)
      )
  }
end
