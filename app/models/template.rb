class Template < ApplicationRecord
  STATUS = {
    draft: "draft",
    published: "published",
    archived: "archived"
  }.freeze

  belongs_to :docente
  has_many :template_questions, dependent: :destroy, inverse_of: :template
  has_many :avaliacoes

  accepts_nested_attributes_for :template_questions, allow_destroy: true

  before_validation :normalize_name

  validates :name, presence: { message: "Informe o nome do template" }, uniqueness: { scope: :docente_id, case_sensitive: false, message: "Já existe um template com esse nome para o docente selecionado" }
  validates :docente, presence: { message: "Selecione o responsável pelo template" }
  validates :status, inclusion: { in: STATUS.values }
  validate :must_have_questions

  enum :status, STATUS

  private

  def normalize_name
    self.name = name.to_s.strip
  end

  def must_have_questions
    return if template_questions.reject(&:marked_for_destruction?).any?

    errors.add(:base, "Adicione pelo menos uma questão")
  end
end
