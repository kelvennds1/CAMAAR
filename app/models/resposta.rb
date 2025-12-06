class Resposta < ApplicationRecord
  self.table_name = "respostas"

  enum status: {
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
