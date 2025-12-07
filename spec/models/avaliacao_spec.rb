require "rails_helper"

RSpec.describe Avaliacao, type: :model do
  subject(:avaliacao) { build(:avaliacao) }

  describe "associations" do
    it { is_expected.to belong_to(:turma) }
    it { is_expected.to belong_to(:docente) }
    it { is_expected.to belong_to(:template).optional }
    it { is_expected.to have_many(:questoes).dependent(:destroy) }
    it { is_expected.to have_many(:respostas).dependent(:destroy) }
    it { is_expected.to accept_nested_attributes_for(:questoes).allow_destroy(true) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:title) }
    it { is_expected.to validate_presence_of(:due_date) }
    it { is_expected.to validate_numericality_of(:max_score).is_greater_than_or_equal_to(0) }
  end

  describe "scopes" do
    describe ".pending_for_dicente" do
      let(:dicente) { create(:dicente) }
      let(:turma) { create(:turma) }
      let!(:matricula) { create(:matricula, dicente:, turma:) }
      let!(:eligible_avaliacao) { create(:avaliacao, turma:, status: :published) }
      let!(:draft_avaliacao) { create(:avaliacao, turma:, status: :draft) }
      let!(:other_turma_avaliacao) { create(:avaliacao) }

      it "returns published evaluations for the dicente's classes" do
        expect(described_class.pending_for_dicente(dicente)).to contain_exactly(eligible_avaliacao)
      end

      it "does not return evaluations from other turmas" do
        expect(described_class.pending_for_dicente(create(:dicente))).to be_empty
      end

      it "does not include non published evaluations" do
        result = described_class.pending_for_dicente(dicente)

        expect(result).not_to include(draft_avaliacao)
      end
    end
  end

  describe "enums" do
    it { is_expected.to define_enum_for(:status).with_values(described_class.statuses).backed_by_column_of_type(:string) }
  end
end
