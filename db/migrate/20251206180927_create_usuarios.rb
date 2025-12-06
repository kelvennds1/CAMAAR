class CreateUsuarios < ActiveRecord::Migration[8.1]
  def change
    create_table :usuarios do |t|
      t.string :identifier, null: false
      t.string :nome, null: false
      t.string :email, null: false
      t.string :formacao
      t.string :ocupacao
      t.string :password_digest
      t.string :type, null: false
      t.string :departamento
      t.string :titulacao
      t.string :matricula
      t.string :curso
      t.boolean :admin, default: false, null: false

      t.timestamps
    end

    add_index :usuarios, :identifier, unique: true
    add_index :usuarios, :email, unique: true
    add_index :usuarios, :matricula, unique: true
    add_index :usuarios, :type
  end
end
