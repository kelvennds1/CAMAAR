# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2025_12_06_181209) do
  create_table "avaliacoes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.integer "docente_id", null: false
    t.datetime "due_date", null: false
    t.integer "max_score", default: 0, null: false
    t.datetime "published_at"
    t.string "status", default: "draft", null: false
    t.integer "template_id"
    t.string "title", null: false
    t.integer "turma_id", null: false
    t.datetime "updated_at", null: false
    t.index ["docente_id"], name: "index_avaliacoes_on_docente_id"
    t.index ["template_id"], name: "index_avaliacoes_on_template_id"
    t.index ["turma_id", "title"], name: "index_avaliacoes_on_turma_id_and_title", unique: true
    t.index ["turma_id"], name: "index_avaliacoes_on_turma_id"
  end

  create_table "materias", force: :cascade do |t|
    t.string "code", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_materias_on_code", unique: true
  end

  create_table "matriculas", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "dicente_id", null: false
    t.date "enrollment_date"
    t.decimal "final_grade", precision: 5, scale: 2
    t.string "status", default: "ativo", null: false
    t.integer "turma_id", null: false
    t.datetime "updated_at", null: false
    t.index ["dicente_id", "turma_id"], name: "index_matriculas_on_dicente_id_and_turma_id", unique: true
    t.index ["dicente_id"], name: "index_matriculas_on_dicente_id"
    t.index ["turma_id"], name: "index_matriculas_on_turma_id"
  end

  create_table "questoes", force: :cascade do |t|
    t.integer "avaliacao_id", null: false
    t.datetime "created_at", null: false
    t.boolean "mandatory", default: true, null: false
    t.integer "max_value"
    t.integer "min_value"
    t.text "options"
    t.integer "position", null: false
    t.text "prompt", null: false
    t.string "question_type", null: false
    t.integer "template_question_id"
    t.datetime "updated_at", null: false
    t.integer "weight", default: 1, null: false
    t.index ["avaliacao_id", "position"], name: "index_questoes_on_avaliacao_id_and_position", unique: true
    t.index ["avaliacao_id"], name: "index_questoes_on_avaliacao_id"
    t.index ["template_question_id"], name: "index_questoes_on_template_question_id"
  end

  create_table "resposta_items", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "questao_id", null: false
    t.integer "resposta_id", null: false
    t.datetime "updated_at", null: false
    t.text "valor", null: false
    t.index ["questao_id"], name: "index_resposta_items_on_questao_id"
    t.index ["resposta_id", "questao_id"], name: "index_resposta_items_on_resposta_id_and_questao_id", unique: true
    t.index ["resposta_id"], name: "index_resposta_items_on_resposta_id"
  end

  create_table "respostas", force: :cascade do |t|
    t.integer "avaliacao_id", null: false
    t.datetime "created_at", null: false
    t.integer "dicente_id", null: false
    t.text "feedback"
    t.decimal "score", precision: 5, scale: 2
    t.string "status", default: "pending", null: false
    t.datetime "submitted_at"
    t.datetime "updated_at", null: false
    t.index ["avaliacao_id", "dicente_id"], name: "index_respostas_on_avaliacao_id_and_dicente_id", unique: true
    t.index ["avaliacao_id"], name: "index_respostas_on_avaliacao_id"
    t.index ["dicente_id"], name: "index_respostas_on_dicente_id"
  end

  create_table "template_questions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "default_value"
    t.integer "max_value"
    t.integer "min_value"
    t.text "options"
    t.integer "position", default: 1, null: false
    t.text "prompt", null: false
    t.string "question_type", null: false
    t.boolean "required", default: true, null: false
    t.integer "template_id", null: false
    t.datetime "updated_at", null: false
    t.index ["template_id", "position"], name: "index_template_questions_on_template_id_and_position", unique: true
    t.index ["template_id"], name: "index_template_questions_on_template_id"
  end

  create_table "templates", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.integer "docente_id", null: false
    t.string "name", null: false
    t.string "status", default: "draft", null: false
    t.datetime "updated_at", null: false
    t.index ["docente_id", "name"], name: "index_templates_on_docente_id_and_name", unique: true
    t.index ["docente_id"], name: "index_templates_on_docente_id"
  end

  create_table "turmas", force: :cascade do |t|
    t.string "class_code", null: false
    t.datetime "created_at", null: false
    t.integer "docente_id", null: false
    t.integer "materia_id", null: false
    t.string "semester", null: false
    t.string "time_slot"
    t.datetime "updated_at", null: false
    t.index ["docente_id"], name: "index_turmas_on_docente_id"
    t.index ["materia_id", "class_code", "semester"], name: "index_turmas_on_materia_code_and_semester", unique: true
    t.index ["materia_id"], name: "index_turmas_on_materia_id"
  end

  create_table "usuarios", force: :cascade do |t|
    t.boolean "admin", default: false, null: false
    t.datetime "created_at", null: false
    t.string "curso"
    t.string "departamento"
    t.string "email", null: false
    t.string "formacao"
    t.string "identifier", null: false
    t.string "matricula"
    t.string "nome", null: false
    t.string "ocupacao"
    t.string "password_digest"
    t.string "titulacao"
    t.string "type", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_usuarios_on_email", unique: true
    t.index ["identifier"], name: "index_usuarios_on_identifier", unique: true
    t.index ["matricula"], name: "index_usuarios_on_matricula", unique: true
    t.index ["type"], name: "index_usuarios_on_type"
  end

  add_foreign_key "avaliacoes", "templates"
  add_foreign_key "avaliacoes", "turmas"
  add_foreign_key "avaliacoes", "usuarios", column: "docente_id"
  add_foreign_key "matriculas", "turmas"
  add_foreign_key "matriculas", "usuarios", column: "dicente_id"
  add_foreign_key "questoes", "avaliacoes"
  add_foreign_key "questoes", "template_questions"
  add_foreign_key "resposta_items", "questoes"
  add_foreign_key "resposta_items", "respostas"
  add_foreign_key "respostas", "avaliacoes"
  add_foreign_key "respostas", "usuarios", column: "dicente_id"
  add_foreign_key "template_questions", "templates"
  add_foreign_key "templates", "usuarios", column: "docente_id"
  add_foreign_key "turmas", "materias"
  add_foreign_key "turmas", "usuarios", column: "docente_id"
end
