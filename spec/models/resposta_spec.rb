require "rails_helper"

RSpec.describe Resposta, type: :model do
  let(:avaliacao) { create(:avaliacao) }
  let(:dicente) { create(:dicente) }
  subject(:resposta) { build(:resposta, avaliacao:, dicente:) }

  describe "associations" do
    it { is_expected.to belong_to(:avaliacao) }
    it { is_expected.to belong_to(:dicente) }
    it { is_expected.to have_many(:resposta_items).dependent(:destroy) }
    it { is_expected.to accept_nested_attributes_for(:resposta_items) }
  end

  describe "validations" do
    it { is_expected.to validate_uniqueness_of(:dicente_id).scoped_to(:avaliacao_id) }
  end

  describe "enums" do
    it { is_expected.to define_enum_for(:status).with_values(described_class.statuses).backed_by_column_of_type(:string) }
  end
end
