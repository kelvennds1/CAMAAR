class CreateMatriculas < ActiveRecord::Migration[8.1]
  def change
    create_table :matriculas do |t|
      t.references :dicente, null: false, foreign_key: { to_table: :usuarios }
      t.references :turma, null: false, foreign_key: true
      t.string :status, null: false, default: "ativo"
      t.date :enrollment_date
      t.decimal :final_grade, precision: 5, scale: 2

      t.timestamps
    end

    add_index :matriculas, [:dicente_id, :turma_id], unique: true
  end
end
