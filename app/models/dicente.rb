class Dicente < Usuario
  has_many :matriculas, dependent: :destroy
  has_many :turmas, through: :matriculas
  has_many :avaliacoes, through: :turmas
  has_many :respostas, dependent: :destroy

  validates :matricula, :curso, presence: true
end
