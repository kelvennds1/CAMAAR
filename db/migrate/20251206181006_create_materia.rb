class CreateMateria < ActiveRecord::Migration[8.1]
  def change
    create_table :materias do |t|
      t.string :code, null: false
      t.string :name, null: false

      t.timestamps
    end

    add_index :materias, :code, unique: true
  end
end
