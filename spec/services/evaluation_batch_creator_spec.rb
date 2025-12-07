require "rails_helper"

RSpec.describe EvaluationBatchCreator do
  describe ".call" do
    let(:template) { create(:template) }
    let(:turmas) { create_list(:turma, 2) }
    let(:due_date) { 2.weeks.from_now.to_date }

    it "creates evaluations for each turma" do
      result = described_class.call(template_id: template.id, turma_ids: turmas.map(&:id), due_date: due_date.to_s)

      expect(result).to be_success
      expect(result.created.size).to eq(2)
      expect(result.skipped).to be_empty

      first_evaluation = result.created.first
      expect(first_evaluation.title).to include(template.name)
      expect(first_evaluation.max_score).to eq(template.template_questions.count * 5)
      expect(first_evaluation.due_date.to_date).to eq(due_date)
      expect(first_evaluation.questoes.count).to eq(template.template_questions.count)
    end

    it "skips turmas that already have evaluations for the template" do
      existing_turma = turmas.first
      create(:avaliacao, turma: existing_turma, template: template)

      result = described_class.call(template_id: template.id, turma_ids: turmas.map(&:id), due_date: due_date.to_s)

      expect(result.created.size).to eq(1)
      expect(result.skipped).to contain_exactly(existing_turma)
    end

    it "returns errors when params are missing" do
      result = described_class.call(template_id: nil, turma_ids: [])

      expect(result).not_to be_success
      expect(result.errors).to include("Selecione ao menos um template e uma turma")
    end

    it "returns an error when the template does not exist" do
      result = described_class.call(template_id: 0, turma_ids: turmas.map(&:id))

      expect(result).not_to be_success
      expect(result.errors).to include("Template selecionado não foi encontrado")
    end
  end
end
