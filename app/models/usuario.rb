class Usuario < ApplicationRecord
	self.inheritance_column = :type

	has_secure_password validations: false

	validates :identifier, :nome, :email, :type, presence: true
	validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, uniqueness: true
	validates :identifier, uniqueness: true
	validates :matricula, uniqueness: true, allow_blank: true

	scope :docentes, -> { where(type: "Docente") }
	scope :dicentes, -> { where(type: "Dicente") }

	def docente?
		is_a?(Docente)
	end

	def dicente?
		is_a?(Dicente)
	end
end
