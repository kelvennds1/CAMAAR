require "rails_helper"

RSpec.describe Matricula, type: :model do
  subject(:matricula) { build(:matricula) }

  describe "associations" do
    it { is_expected.to belong_to(:dicente) }
    it { is_expected.to belong_to(:turma) }
  end

  describe "validations" do
    it { is_expected.to validate_uniqueness_of(:dicente_id).scoped_to(:turma_id) }
  end

  describe "enums" do
    it { is_expected.to define_enum_for(:status).with_values(described_class.statuses).backed_by_column_of_type(:string) }
  end
end
