##
# Model representing an evaluation template.
# Templates define reusable question sets that can be applied to create evaluations.
#
# ==== Attributes
# * +name+ - Template name (unique per docente)
# * +status+ - Current status (draft, published, archived)
#
# ==== Associations
# * +docente+ - Teacher who owns this template
# * +template_questions+ - Questions in this template
# * +avaliacoes+ - Evaluations created from this template
#
class Template < ApplicationRecord
  STATUS = {
    draft: "draft",
    published: "published",
    archived: "archived"
  }.freeze

  belongs_to :docente
  has_many :template_questions, dependent: :destroy, inverse_of: :template
  has_many :avaliacoes, dependent: :nullify

  accepts_nested_attributes_for :template_questions, allow_destroy: true

  before_validation :normalize_name

  validates :name, presence: { message: "Informe o nome do template" }, uniqueness: { scope: :docente_id, case_sensitive: false, message: "Já existe um template com esse nome para o docente selecionado" }
  validates :docente, presence: { message: "Selecione o responsável pelo template" }
  validates :status, inclusion: { in: STATUS.values }
  validate :must_have_questions

  enum :status, STATUS

  private

  ##
  # Normalizes template name by stripping whitespace.
  #
  def normalize_name
    self.name = name.to_s.strip
  end

  ##
  # Validates that template has at least one non-destroyed question.
  #
  def must_have_questions
    return if template_questions.reject(&:marked_for_destruction?).any?

    errors.add(:base, "Adicione pelo menos uma questão")
  end
end
