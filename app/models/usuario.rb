##
<<<<<<< HEAD
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
=======
# Base model for all users in the system.
# Uses Single Table Inheritance (STI) to represent different user types (Docente, Dicente).
>>>>>>> sprint-3-documentacao
#
class Usuario < ApplicationRecord
	self.inheritance_column = :type

	has_secure_password validations: false

	validates :identifier, :nome, :email, :type, presence: true
	validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, uniqueness: true
	validates :identifier, uniqueness: true
	validates :matricula, uniqueness: true, allow_blank: true

	##
	# Finds all teachers (docentes).
	#
	# ==== Returns
	# * ActiveRecord::Relation - Collection of Docente records
	#
	scope :docentes, -> { where(type: "Docente") }

	##
	# Finds all students (dicentes).
	#
	# ==== Returns
	# * ActiveRecord::Relation - Collection of Dicente records
	#
	scope :dicentes, -> { where(type: "Dicente") }

	##
<<<<<<< HEAD
	# Checks if user is a teacher.
	#
	# ==== Returns
	# * Boolean - true if user is a Docente instance
=======
	# Checks if user is a teacher (docente).
	#
	# ==== Returns
	# * Boolean - true if user is a Docente, false otherwise
>>>>>>> sprint-3-documentacao
	#
	def docente?
		is_a?(Docente)
	end

	##
<<<<<<< HEAD
	# Checks if user is a student.
	#
	# ==== Returns
	# * Boolean - true if user is a Dicente instance
=======
	# Checks if user is a student (dicente).
	#
	# ==== Returns
	# * Boolean - true if user is a Dicente, false otherwise
>>>>>>> sprint-3-documentacao
	#
	def dicente?
		is_a?(Dicente)
	end
end
