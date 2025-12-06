class Materia < ApplicationRecord
	self.table_name = "materias"

	has_many :turmas, dependent: :destroy

	validates :code, :name, presence: true
	validates :code, uniqueness: true
end
