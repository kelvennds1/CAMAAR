require "rails_helper"

RSpec.describe Usuario, type: :model do
  subject(:usuario) { build(:docente) }

  describe "validations" do
    it { is_expected.to validate_presence_of(:identifier) }
    it { is_expected.to validate_presence_of(:nome) }
    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_presence_of(:type) }
    it { is_expected.to validate_uniqueness_of(:email) }
    it { is_expected.to validate_uniqueness_of(:identifier) }
    it { is_expected.to validate_uniqueness_of(:matricula).allow_nil }

    it "validates email format" do
      usuario.email = "invalid"

      expect(usuario).not_to be_valid
      expect(usuario.errors[:email]).to be_present
    end
  end

  describe "authentication helpers" do
    it "responds to authenticate from has_secure_password" do
      usuario.password = "senha-secreta"
      expect(usuario.authenticate("senha-secreta")).to be_truthy
    end

    it "identifies docentes and dicentes" do
      expect(usuario.docente?).to be(true)
      expect(usuario.dicente?).to be(false)
    end
  end
end
