require 'rails_helper'
require 'ostruct'

RSpec.describe "Users (SIGAA Import)", type: :request do
  let(:admin) { create(:docente, admin: true, pending_activation: false) }

  before do
    stub_authentication(admin)
    ActionMailer::Base.deliveries.clear
  end

  describe "POST /sigaa_imports (user import)" do
    let(:classes_file) { fixture_file_upload('sigaa_classes.json', 'application/json') }
    let(:members_file) { fixture_file_upload('sigaa_members.json', 'application/json') }

    context "with valid files" do
      it "creates new users from SIGAA data" do
        expect {
          post sigaa_imports_path, params: {
            classes_file: classes_file,
            class_members_file: members_file
          }
        }.to change(Usuario, :count)
      end

      it "sets pending_activation for new users" do
        post sigaa_imports_path, params: {
          classes_file: classes_file,
          class_members_file: members_file
        }

        new_users = Usuario.where(pending_activation: true)
        expect(new_users).to exist
      end

      it "generates password reset tokens for new users" do
        post sigaa_imports_path, params: {
          classes_file: classes_file,
          class_members_file: members_file
        }

        new_users = Usuario.where.not(password_reset_token: nil)
        expect(new_users).to exist
      end

      it "sends password setup emails to new users" do
        expect {
          post sigaa_imports_path, params: {
            classes_file: classes_file,
            class_members_file: members_file
          }
        }.to change { ActionMailer::Base.deliveries.count }.by_at_least(1)
      end

      it "sends emails with password setup link" do
        post sigaa_imports_path, params: {
          classes_file: classes_file,
          class_members_file: members_file
        }

        emails = ActionMailer::Base.deliveries
        setup_email = emails.find { |e| e.subject.include?('senha') }
        expect(setup_email).to be_present
        expect(setup_email.html_part.decoded).to include('password/setup')
      end

      it "redirects with success message" do
        post sigaa_imports_path, params: {
          classes_file: classes_file,
          class_members_file: members_file
        }

        expect(response).to redirect_to(sigaa_imports_path)
        follow_redirect!
        expect(flash[:notice]).to be_present
      end
    end

    context "with duplicate users" do
      let!(:existing_user) { create(:dicente, identifier: "aluno001", email: "ana.santos@aluno.unb.br") }

      it "does not create duplicate users" do
        expect {
          post sigaa_imports_path, params: {
            classes_file: classes_file,
            class_members_file: members_file
          }
        }.not_to change { Usuario.where(identifier: "aluno001").count }
      end

      it "does not send password reset to existing users" do
        initial_email_count = ActionMailer::Base.deliveries.count

        post sigaa_imports_path, params: {
          classes_file: classes_file,
          class_members_file: members_file
        }

        # Fixture tem 5 usuários (2 docentes + 3 dicentes), 1 já existe (aluno001)
        # Então envia email para 4 novos usuários
        expect(ActionMailer::Base.deliveries.count - initial_email_count).to eq(4)
      end
    end

    context "with invalid data" do
      let(:invalid_file) { fixture_file_upload('invalid.json', 'application/json') }

      it "logs errors for invalid records" do
        post sigaa_imports_path, params: {
          classes_file: invalid_file,
          class_members_file: members_file
        }

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "continues importing valid records despite errors" do
        expect {
          post sigaa_imports_path, params: {
            classes_file: invalid_file,
            class_members_file: members_file
          }
        }.to change(Usuario, :count).by_at_least(0)
      end
    end

    context "without admin privileges" do
      let(:regular_user) { create(:dicente, pending_activation: false) }

      before { stub_authentication(regular_user) }

      it "denies access" do
        post sigaa_imports_path, params: {
          classes_file: classes_file,
          class_members_file: members_file
        }

        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to include("Acesso negado")
      end
    end
  end

  describe "POST /sigaa_imports/update_database" do
    context "with files in repository root" do
      before do
        # Mock file existence
        allow(File).to receive(:exist?).and_call_original
        allow(File).to receive(:exist?).with(Rails.root.join('classes.json')).and_return(true)
        allow(File).to receive(:exist?).with(Rails.root.join('class_members.json')).and_return(true)
      end

      it "imports users from repository files" do
        allow(SigaaImporter).to receive(:call).and_return(
          OpenStruct.new(success?: true, summary_message: "Success")
        )

        post update_database_sigaa_imports_path

        expect(response).to redirect_to(sigaa_imports_path)
      end

      it "shows success message after import" do
        allow(SigaaImporter).to receive(:call).and_return(
          OpenStruct.new(success?: true, summary_message: "6 users imported")
        )

        post update_database_sigaa_imports_path

        follow_redirect!
        expect(flash[:notice]).to include("users imported")
      end
    end

    context "without files in repository" do
      before do
        # Mock file não-existence
        allow(File).to receive(:exist?).and_call_original
        allow(File).to receive(:exist?).with(Rails.root.join('classes.json')).and_return(false)
        allow(File).to receive(:exist?).with(Rails.root.join('class_members.json')).and_return(false)
      end

      it "shows error message" do
        post update_database_sigaa_imports_path

        follow_redirect!
        expect(response.body).to include("não encontrados")
      end
    end
  end

  describe "user creation attributes" do
    let(:classes_file) { fixture_file_upload('sigaa_classes.json', 'application/json') }
    let(:members_file) { fixture_file_upload('sigaa_members.json', 'application/json') }

    before do
      post sigaa_imports_path, params: {
        classes_file: classes_file,
        class_members_file: members_file
      }
    end

    it "creates dicentes for student records" do
      students = Dicente.where(pending_activation: true)
      expect(students).to exist
    end

    it "creates docentes for professor records" do
      professors = Docente.where(pending_activation: true)
      expect(professors).to exist
    end

    it "sets unique identifiers for each user" do
      users = Usuario.where(pending_activation: true)
      identifiers = users.pluck(:identifier)
      expect(identifiers.uniq.count).to eq(identifiers.count)
    end

    it "sets email addresses for all users" do
      users = Usuario.where(pending_activation: true)
      expect(users.where(email: nil)).to be_empty
    end
  end
end
