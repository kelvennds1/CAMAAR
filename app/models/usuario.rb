##
# Base model for all users in the system.
# Uses Single Table Inheritance (STI) to represent different user types (Docente, Dicente).
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
	# Checks if user is a teacher (docente).
	#
	# ==== Returns
	# * Boolean - true if user is a Docente, false otherwise
	#
	def docente?
		is_a?(Docente)
	end

	##
	# Checks if user is a student (dicente).
	#
	# ==== Returns
	# * Boolean - true if user is a Dicente, false otherwise
	#
	def dicente?
		is_a?(Dicente)
	end
end
