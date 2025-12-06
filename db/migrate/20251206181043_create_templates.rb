class CreateTemplates < ActiveRecord::Migration[8.1]
  def change
    create_table :templates do |t|
      t.references :docente, null: false, foreign_key: { to_table: :usuarios }
      t.string :name, null: false
      t.text :description
      t.string :status, null: false, default: "draft"

      t.timestamps
    end

    add_index :templates, [:docente_id, :name], unique: true
  end
end
