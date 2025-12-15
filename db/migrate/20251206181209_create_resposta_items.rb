class CreateRespostaItems < ActiveRecord::Migration[8.1]
  def change
    create_table :resposta_items do |t|
      t.references :resposta, null: false, foreign_key: true
      t.references :questao, null: false, foreign_key: { to_table: :questoes }
      t.text :valor, null: false

      t.timestamps
    end

    add_index :resposta_items, [ :resposta_id, :questao_id ], unique: true
  end
end
