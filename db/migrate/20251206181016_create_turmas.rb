class CreateTurmas < ActiveRecord::Migration[8.1]
  def change
    create_table :turmas do |t|
      t.references :materia, null: false, foreign_key: true
      t.references :docente, null: false, foreign_key: { to_table: :usuarios }
      t.string :class_code, null: false
      t.string :semester, null: false
      t.string :time_slot

      t.timestamps
    end

    add_index :turmas, [:materia_id, :class_code, :semester], unique: true, name: "index_turmas_on_materia_code_and_semester"
  end
end
