##
# Model representing a subject/course in the system.
#
# ==== Attributes
# * +code+ - Subject code (unique identifier, e.g., "MAT001")
# * +name+ - Subject name
#
# ==== Associations
# * +turmas+ - Class sections of this subject
#
class Materia < ApplicationRecord
	self.table_name = "materias"

	has_many :turmas, dependent: :destroy

	validates :code, :name, presence: true
	validates :code, uniqueness: true
end
