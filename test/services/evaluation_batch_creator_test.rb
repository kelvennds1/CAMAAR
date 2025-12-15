require "test_helper"

class EvaluationBatchCreatorTest < ActiveSupport::TestCase
  setup do
    @docente = create_docente
    @materia = Materia.create!(code: "MAT-#{SecureRandom.hex(2)}", name: "Matemática Aplicada")
    @template = build_template(@docente)
    @turmas = Array.new(2) { |index| build_turma(index) }
  end

  test "creates evaluations for each selected class" do
    due_date = 1.month.from_now.change(hour: 12)

    result = EvaluationBatchCreator.call(
      template_id: @template.id,
      turma_ids: @turmas.map(&:id),
      due_date: due_date.iso8601
    )

    assert_predicate result, :success?
    assert_equal 2, result.created.size
    assert_equal 0, result.skipped.size

    titles = Avaliacao.pluck(:title)
    assert_includes titles, "#{@template.name} - #{@turmas.first.class_code}/#{@turmas.first.semester}"
    assert_equal @template.template_questions.count, result.created.first.questoes.count
  end

  test "skips classes that already have an evaluation" do
    Avaliacao.create!(
      template: @template,
      turma: @turmas.first,
      docente: @turmas.first.docente,
      title: "#{@template.name} - #{@turmas.first.class_code}/#{@turmas.first.semester}",
      due_date: Time.zone.today.end_of_month,
      max_score: 5
    )

    result = EvaluationBatchCreator.call(template_id: @template.id, turma_ids: @turmas.map(&:id))

    assert_predicate result, :success?
    assert_equal 1, result.created.size
    assert_equal [ @turmas.first ], result.skipped
  end

  test "returns validation error when parameters are missing" do
    result = EvaluationBatchCreator.call(template_id: nil, turma_ids: [])

    assert_not result.success?
    assert_includes result.errors, "Selecione ao menos um template e uma turma"
  end

  private

  def build_template(docente)
    Template.create!(
      name: "Template #{SecureRandom.hex(3)}",
      description: "Avaliação institucional",
      status: Template::STATUS[:draft],
      docente: docente,
      template_questions_attributes: [
        {
          prompt: "Como você avalia o curso?",
          question_type: TemplateQuestion::QUESTION_TYPES[:likert],
          min_value: 1,
          max_value: 5,
          position: 1
        }
      ]
    )
  end

  def build_turma(index)
    Turma.create!(
      class_code: "T#{index + 1}#{SecureRandom.hex(1)}",
      semester: current_semester_label,
      materia: @materia,
      docente: @docente,
      time_slot: "Seg 10h"
    )
  end

  def current_semester_label
    date = Time.zone.today
    term = date.month <= 6 ? 1 : 2
    format("%<year>d.%<term>d", year: date.year, term: term)
  end
end
