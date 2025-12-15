class CreateTemplateQuestions < ActiveRecord::Migration[8.1]
  def change
    create_table :template_questions do |t|
      t.references :template, null: false, foreign_key: true
      t.text :prompt, null: false
      t.string :question_type, null: false
      t.boolean :required, null: false, default: true
      t.string :default_value
      t.integer :position, null: false, default: 1
      t.text :options
      t.integer :min_value
      t.integer :max_value

      t.timestamps
    end

    add_index :template_questions, [ :template_id, :position ], unique: true
  end
end
