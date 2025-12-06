class CreateResposta < ActiveRecord::Migration[8.1]
  def change
    create_table :respostas do |t|
      t.references :avaliacao, null: false, foreign_key: { to_table: :avaliacoes }
      t.references :dicente, null: false, foreign_key: { to_table: :usuarios }
      t.string :status, null: false, default: "pending"
      t.decimal :score, precision: 5, scale: 2
      t.datetime :submitted_at
      t.text :feedback

      t.timestamps
    end

    add_index :respostas, [:avaliacao_id, :dicente_id], unique: true
  end
end
