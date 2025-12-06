class CreateAvaliacaos < ActiveRecord::Migration[8.1]
  def change
    create_table :avaliacoes do |t|
      t.references :turma, null: false, foreign_key: true
      t.references :docente, null: false, foreign_key: { to_table: :usuarios }
      t.references :template, foreign_key: true
      t.string :title, null: false
      t.text :description
      t.datetime :due_date, null: false
      t.string :status, null: false, default: "draft"
      t.integer :max_score, null: false, default: 0
      t.datetime :published_at

      t.timestamps
    end

    add_index :avaliacoes, [:turma_id, :title], unique: true
  end
end
