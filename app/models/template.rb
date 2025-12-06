class Template < ApplicationRecord
  STATUS = {
    draft: "draft",
    published: "published",
    archived: "archived"
  }.freeze

  belongs_to :docente
  has_many :template_questions, dependent: :destroy
  has_many :avaliacoes

  accepts_nested_attributes_for :template_questions, allow_destroy: true

  validates :name, :status, presence: true
  validates :status, inclusion: { in: STATUS.values }

  enum status: STATUS
end
