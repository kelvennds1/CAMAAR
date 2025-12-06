class Docente < Usuario
  has_many :turmas, dependent: :nullify
  has_many :templates, dependent: :destroy
  has_many :avaliacoes, dependent: :nullify

  validates :departamento, :titulacao, presence: true
end
