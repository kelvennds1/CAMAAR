require "rails_helper"

RSpec.describe "SIGAA Imports", type: :request do
  let(:admin) { create(:docente, admin: true) }
  let(:uploaded_file) { Rack::Test::UploadedFile.new(Rails.root.join("classes.json"), "application/json") }

  before do
    stub_authentication(admin)
  end

  describe "POST /sigaa_imports" do
    context "when the import succeeds" do
      let(:result) { instance_double(SigaaImporter::ImportResult, success?: true, summary_message: "Importação concluída", errors: []) }

      it "redirects back with a success notice" do
        allow(SigaaImporter).to receive(:call).and_return(result)

        post sigaa_imports_path, params: { classes_file: uploaded_file }

        expect(response).to redirect_to(sigaa_imports_path)
        follow_redirect!
        expect(response.body).to include("Importação concluída")
      end
    end

    context "when the import fails" do
      let(:result) { instance_double(SigaaImporter::ImportResult, success?: false, summary_message: nil, errors: [ "Falha na importação" ]) }

      it "re-renders the form with the error message" do
        allow(SigaaImporter).to receive(:call).and_return(result)

        post sigaa_imports_path, params: { classes_file: uploaded_file }

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include("Falha na importação")
      end
    end
  end

  describe "POST /sigaa_imports/update_database" do
    let(:result) { instance_double(SigaaImporter::ImportResult, success?: true, summary_message: "Atualização concluída", errors: []) }

    it "triggers an update using the repository JSON files" do
      expect(SigaaImporter).to receive(:call).with(
        classes_file: Rails.root.join("classes.json").to_s,
        class_members_file: Rails.root.join("class_members.json").to_s,
        operation_type: "Atualização"
      ).and_return(result)

      post update_database_sigaa_imports_path

      expect(response).to redirect_to(sigaa_imports_path)
      follow_redirect!
      expect(response.body).to include("Atualização concluída")
    end
  end

  context "when the current user is not an admin" do
    before do
      stub_authentication(create(:docente, admin: false))
    end

    it "blocks the request" do
      expect(SigaaImporter).not_to receive(:call)

      post sigaa_imports_path

      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to eq("Acesso negado")
    end
  end
end
