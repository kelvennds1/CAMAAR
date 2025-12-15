##
# Model representing a student's response to an evaluation.
# Contains the submission metadata and links to individual answer items.
#
# ==== Attributes
# * +status+ - Response status (pending, submitted, reviewed)
# * +submitted_at+ - Timestamp when response was submitted
#
# ==== Associations
# * belongs_to :avaliacao - The evaluation being responded to
# * belongs_to :dicente - The student who submitted this response
# * has_many :resposta_items - Individual answers to each question
#
# ==== Validations
# * One response per student per evaluation (unique dicente_id + avaliacao_id)
#
class Resposta < ApplicationRecord
  self.table_name = "respostas"

  enum :status, {
    pending: "pending",
    submitted: "submitted",
    reviewed: "reviewed"
  }

  belongs_to :avaliacao
  belongs_to :dicente

  has_many :resposta_items, dependent: :destroy

  accepts_nested_attributes_for :resposta_items

  validates :dicente_id, uniqueness: { scope: :avaliacao_id }
end
