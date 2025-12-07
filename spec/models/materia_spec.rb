require "rails_helper"

RSpec.describe Materia, type: :model do
  subject(:materia) { build(:materia) }

  describe "associations" do
    it { is_expected.to have_many(:turmas).dependent(:destroy) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:code) }
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:code) }
  end
end
