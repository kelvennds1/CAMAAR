##
# Base model for all system users (STI parent class).
# Uses Single Table Inheritance (STI) with Docente and Dicente subclasses.
#
# ==== Attributes
# * +identifier+ - Unique user identifier (login/username)
# * +nome+ - User's full name
# * +email+ - User's email address (must be unique)
# * +matricula+ - Registration number (optional, unique if present)
# * +type+ - STI discriminator column (Docente or Dicente)
# * +password_digest+ - Encrypted password (via has_secure_password)
# * +pending_activation+ - Whether user needs to set up password
# * +activation_token+ - Token for password setup
# * +activation_token_expires_at+ - Token expiration datetime
#
class Usuario < ApplicationRecord
	self.inheritance_column = :type

	has_secure_password validations: false

	validates :identifier, :nome, :email, :type, presence: true
	validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, uniqueness: true
	validates :identifier, uniqueness: true
	validates :matricula, uniqueness: true, allow_blank: true

	scope :docentes, -> { where(type: "Docente") }
	scope :dicentes, -> { where(type: "Dicente") }

	##
	# Checks if user is a teacher.
	#
	# ==== Returns
	# * Boolean - true if user is a Docente instance
	#
	def docente?
		is_a?(Docente)
	end

	##
	# Checks if user is a student.
	#
	# ==== Returns
	# * Boolean - true if user is a Dicente instance
	#
	def dicente?
		is_a?(Dicente)
	end
end
