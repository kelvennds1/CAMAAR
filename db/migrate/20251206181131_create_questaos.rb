class CreateQuestaos < ActiveRecord::Migration[8.1]
  def change
    create_table :questoes do |t|
      t.references :avaliacao, null: false, foreign_key: { to_table: :avaliacoes }
      t.references :template_question, foreign_key: true
      t.text :prompt, null: false
      t.string :question_type, null: false
      t.integer :position, null: false
      t.text :options
      t.integer :min_value
      t.integer :max_value
      t.integer :weight, null: false, default: 1
      t.boolean :mandatory, null: false, default: true

      t.timestamps
    end

    add_index :questoes, [:avaliacao_id, :position], unique: true
  end
end
