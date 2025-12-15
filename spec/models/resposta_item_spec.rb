require "rails_helper"

RSpec.describe RespostaItem, type: :model do
  let(:avaliacao) { create(:avaliacao) }
  let(:resposta) { create(:resposta, avaliacao:) }
  let(:questao) { create(:questao, avaliacao:) }

  subject(:resposta_item) { build(:resposta_item, resposta:, questao:) }

  describe "associations" do
    it { is_expected.to belong_to(:resposta) }
    it { is_expected.to belong_to(:questao) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:valor) }
    it { is_expected.to validate_uniqueness_of(:questao_id).scoped_to(:resposta_id) }
  end
end
